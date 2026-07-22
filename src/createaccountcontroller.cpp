#include "account.h"
#include "asset.h"
#include "context.h"
#include "controllers/lwkamp2accountcontroller.h"
#include "createaccountcontroller.h"
#include "ga.h"
#include "json.h"
#include "lwk/lwk.hpp"
#include "network.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

#include <gdk.h>
#include <wally_wrapper.h>

#include <QtConcurrentRun>

namespace {

bool IsValidXpub(const QString& xpub)
{
    ext_key key;
    const auto rc = bip32_key_from_base58(xpub.toUtf8().constData(), &key);
    return rc == WALLY_OK;
}

bool IsValidDescriptor(const QString& input)
{
    wally_descriptor* out{nullptr};
    const auto rc = wally_descriptor_parse(input.toUtf8().constData(), NULL, WALLY_NETWORK_NONE, 0, &out);
    if (out) wally_descriptor_free(out);
    return rc == WALLY_OK;
}

} // namespace

CreateAccountController::CreateAccountController(QObject *parent)
    : Controller(parent)
{
}

void CreateAccountController::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
}

void CreateAccountController::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
}

void CreateAccountController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged();

    clearError("create");
}

void CreateAccountController::setRecoveryMnemonic(const QStringList& recovery_mnemonic)
{
    if (m_recovery_mnemonic == recovery_mnemonic) return;
    m_recovery_mnemonic = recovery_mnemonic;
    emit recoveryMnemonicChanged();
    if (!m_recovery_xpub.isEmpty()) {
        m_recovery_xpub.clear();
        emit recoveryXpubChanged();
    }
}

QStringList CreateAccountController::generateMnemonic(int size) const
{
    return gdk::generate_mnemonic(size);
}

void CreateAccountController::create()
{
    Q_ASSERT(noErrors());

    auto monitor = new TaskGroupMonitor(this);
    setMonitor(monitor);
    m_error = {};
    m_account = nullptr;
    emit errorChanged();

    if (m_type == "amp2") {
        createAmp2Account();
    } else {
        ensureSession();
    }
}

void CreateAccountController::setBusy(bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit busyChanged();
}

void CreateAccountController::createAmp2Account()
{
    // The AMP2 path has no task group driving monitor->idle, so m_busy is
    // what gates the QML button; it also guards against a double-click
    // racing two register_wallet calls.
    if (m_busy) return;
    qDebug() << Q_FUNC_INFO << "starting AMP2 account creation on" << m_network;
    const auto mnemonic = context()->credentials().value("mnemonic").toString();
    if (mnemonic.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "no mnemonic available, aborting";
        m_error = "AMP2 account creation requires a software signer.";
        emit errorChanged();
        emit failed(m_error);
        return;
    }

    struct Result {
        bool ok{false};
        QString error;
        QString wid;
        std::shared_ptr<lwk::Amp2> amp2;
        std::shared_ptr<lwk::Wollet> wollet;
    };

    // No AMP2 wid exists yet, so context()->amp2AccountController() would
    // return nullptr; use a throwaway controller instance purely to run
    // deriveAmp2(), then hand off to the real (cached) controller below once
    // registration succeeds and the wid is persisted.
    auto derive_controller = new LwkAmp2AccountController(this);
    derive_controller->setContext(context());

    setBusy(true);

    auto future = QtConcurrent::run(derive_controller->threadPool(), [=, this]() -> Result {
        Result result;
        const auto derivation = derive_controller->deriveAmp2();
        if (!derivation.ok) {
            qWarning() << "createAmp2Account: deriveAmp2 failed:" << derivation.error;
            result.error = derivation.error;
            return result;
        }
        try {
            result.wid = QString::fromStdString(derivation.amp2->register_wallet(derivation.amp2_desc));
            qDebug() << "createAmp2Account: registered wallet, wid =" << result.wid;
        } catch (const lwk::lwk_error::Generic& error) {
            qWarning() << "createAmp2Account: register_wallet error:" << error.msg;
            result.error = QString::fromStdString(error.msg);
            return result;
        } catch (...) {
            qWarning() << "createAmp2Account: register_wallet unexpected error";
            result.error = "Unexpected error registering AMP2 account.";
            return result;
        }
        result.amp2 = derivation.amp2;
        result.wollet = derivation.wollet;
        result.ok = true;
        return result;
    });

    future.then(this, [=, this](Result result) {
        derive_controller->deleteLater();
        setBusy(false);

        if (!result.ok) {
            qDebug() << Q_FUNC_INFO << "AMP2 registration failed:" << result.error;
            m_error = result.error;
            emit errorChanged();
            emit failed(m_error);
            return;
        }
        qDebug() << Q_FUNC_INFO << "AMP2 registration succeeded, wid =" << result.wid;

        // Persist the wid so the account can be reloaded on next login. Only the
        // wid is stored (it proves registration); the descriptor is re-derived
        // from the signer at load to keep the blinding key off disk.
        auto wallet = context()->wallet();
        if (wallet) {
            wallet->m_amp2_wid = result.wid;
            wallet->save();
        }

        // context()->amp2AccountController() is gated on the wallet having a
        // registered wid, which was just persisted above, so this now returns
        // a freshly constructed controller.
        auto controller = context()->amp2AccountController();
        if (!wallet || !controller) {
            qWarning() << Q_FUNC_INFO << "AMP2 registered but wallet/controller unavailable";
            m_error = "Unable to finish setting up the AMP2 account.";
            emit errorChanged();
            emit failed(m_error);
            return;
        }
        controller->start(result.wollet, result.amp2);
        m_account = controller->account();
        emit created(m_account);
    });

    waitForFuture(future);
}

void CreateAccountController::ensureSession()
{
    auto session = context()->getOrCreateSession(m_network);
    auto session_connect = new ConnectTask(session);
    auto session_register = session->registerUser();
    auto session_login = session->login();
    connect(session_login, &Task::failed, this, [=, this](const QString& error) {
        m_error = error;
    });
    auto load_accounts = new LoadAccountsTask(false, session);

    session_connect->then(session_register);
    session_register->then(session_login);
    session_login->then(load_accounts);

    auto group = new TaskGroup(this);
    group->add(session_connect);
    group->add(session_register);
    group->add(session_login);
    group->add(load_accounts);

    const auto pricing = context()->primarySession()->settings().value("pricing");
    if (pricing.isObject() && session != context()->primarySession()) {
        auto sync_settings = new ChangeSettingsTask(QJsonObject{{ "pricing", pricing }}, session);
        session_login->then(sync_settings);
        group->add(sync_settings);
    }

    monitor()->add(group);
    dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, [=, this] {
        emit failed(m_error);
    });
    connect(group, &TaskGroup::finished, this, [=, this] {
        ensureAccount();
    });
}

void CreateAccountController::ensureAccount()
{
    QString name;
    if (m_type == "2of2") name = "2FA Protected";
    if (m_type == "2of3") name = "2of3 with 2FA";
    if (m_type == "2of2_no_recovery") name = "AMP";
    if (m_type == "p2wpkh") name = "Standard";
    if (m_type == "p2sh-p2wpkh") name = "Legacy SegWit";
    if (m_type == "p2pkh") name = "Legacy";
    if (m_network->isLiquid()) name.append(" Liquid");
    int n = 1;
    bool retry = true;
    QString suffix;
    while (retry) {
        retry = false;
        if (n > 1) suffix = " " + QString::number(n);
        for (auto account : context()->getAccounts()) {
            if (account->name() == name + suffix) {
                n ++;
                retry = true;
                break;
            }
        }
    }

    auto session = context()->getOrCreateSession(m_network);
    auto group = new TaskGroup(this);
    Task* last = nullptr;
    for (auto account : context()->getAccounts()) {
        if (account->session() != session) continue;
        if (account->pointer() == 0 && account->type() != m_type && account->isEmpty()) {
            auto task = new UpdateAccountTask({
                { "subaccount", static_cast<qint64>(account->pointer()) },
                { "hidden", true }
            }, session);
            account->setHidden(true);
            group->add(task);
            if (last) last->then(task);
            last = task;
            continue;
        }
        if (account->type() != m_type) continue;
        if (account->isMultisig() && account->pointer() > 0) continue;
        if (account->isMultisig() && !account->name().isEmpty()) continue;
        if (account->isSinglesig() && account->json().value("bip44_discovered").toBool()) continue;
        if (account->isSinglesig() && !account->isHidden()) continue;

        auto task = new UpdateAccountTask({
            { "subaccount", static_cast<qint64>(account->pointer()) },
            { "name", account->name().isEmpty() ? name : account->name() },
            { "hidden", false }
        }, session);
        account->setName(name);
        account->setHidden(false);
        m_account = account;
        group->add(task);
        if (last) last->then(task);
        last = task;
        break;
    }

    if (!m_account) {
        auto details = QJsonObject{
            { "name", name + suffix },
            { "type", m_type },
        };

        if (m_type == "2of3") {
            if (!m_recovery_mnemonic.isEmpty()) {
                Q_ASSERT(m_recovery_xpub.isEmpty());
                details["recovery_mnemonic"] = m_recovery_mnemonic.join(" ");
            } else if (!m_recovery_xpub.isEmpty()) {
                details["recovery_xpub"] = m_recovery_xpub;
            } else {
                Q_UNREACHABLE();
            }
        }

        auto create_account = new CreateAccountTask(details, session);
        auto load_accounts = new LoadAccountsTask(false, session);

        group->add(create_account);
        group->add(load_accounts);

        if (last) last->then(create_account);
        create_account->then(load_accounts);
        last = load_accounts;

        connect(create_account, &Task::failed, this, [=, this](const QString& error) {
            m_error = error;
        });
        connect(create_account, &Task::finished, this, [=, this] {
            m_account = context()->getAccountByPointer(m_network, create_account->pointer());
        });
    }

    auto load_config = new LoadTwoFactorConfigTask(session);
    auto load_currencies = new LoadCurrenciesTask(session);

    group->add(load_config);
    group->add(load_currencies);

    if (last) {
        last->then(load_config);
        last->then(load_currencies);
    }

    monitor()->add(group);
    dispatcher()->add(group);

    connect(group, &TaskGroup::finished, this, [=, this] {
        Q_ASSERT(m_account);
        emit created(m_account);
    });
    connect(group, &TaskGroup::failed, this, [=, this] {
        emit failed(m_error);
    });
}

void CreateAccountController::setRecoveryXpub(const QString& recovery_xpub)
{
    if (m_recovery_xpub == recovery_xpub) return;
    if (!m_recovery_mnemonic.isEmpty()) {
        m_recovery_mnemonic.clear();
        emit recoveryMnemonicChanged();
    }
    m_recovery_xpub = recovery_xpub;
    emit recoveryXpubChanged();
}

MnemonicGenerator::MnemonicGenerator(QObject *parent)
    : QObject(parent)
{
    generate();
}

void MnemonicGenerator::setSize(int size)
{
    if (m_size == size) return;
    if (size != 12 && size != 24) return;
    m_size = size;
    emit sizeChanged();
    generate();
}

void MnemonicGenerator::generate()
{
    m_mnemonic = gdk::generate_mnemonic(m_size);
    emit mnemonicChanged();
}

XPubValidator::XPubValidator(QObject* parent)
    : QValidator(parent)
{
}

void XPubValidator::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
}

QValidator::State XPubValidator::validate(QString& input, int& pos) const
{
    Q_UNUSED(pos);
    if (!m_network || (m_network->isMainnet() && !m_network->isLiquid())) {
        for (const auto line : input.split('\n')) {
            if (!IsValidXpub(line)) {
                return QValidator::Intermediate;
            }
        }
    }
    return QValidator::Acceptable;
}

DescriptorValidator::DescriptorValidator(QObject* parent)
    : QValidator(parent)
{
}

void DescriptorValidator::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
}

QValidator::State DescriptorValidator::validate(QString& input, int& pos) const
{
    Q_UNUSED(pos);
    if (!m_network || !m_network->isLiquid()) {
        for (const auto line : input.split('\n')) {
            if (!IsValidDescriptor(line)) return QValidator::Intermediate;
        }
    }
    return QValidator::Acceptable;
}
