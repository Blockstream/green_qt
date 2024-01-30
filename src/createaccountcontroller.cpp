#include "asset.h"
#include "account.h"
#include "createaccountcontroller.h"

#include <gdk.h>
#include <wally_wrapper.h>

#include "context.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

namespace {

bool IsValidXpub(const QString& xpub)
{
    ext_key key;
    const auto rc = bip32_key_from_base58(xpub.toUtf8().constData(), &key);
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

    ensureSession();
}

void CreateAccountController::ensureSession()
{
    auto session = m_context->getOrCreateSession(m_network);
    auto session_connect = new ConnectTask(session);
    auto session_register = session->registerUser();
    auto session_login = session->login();
    connect(session_login, &Task::failed, this, [=](const QString& error) {
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

    monitor()->add(group);
    dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, [=] {
        emit failed(m_error);
    });
    connect(group, &TaskGroup::finished, this, [=] {
        ensureAccount();
    });
}

void CreateAccountController::ensureAccount()
{
    QString name;
    if (m_type == "2of2") name = "2FA Protected";
    if (m_type == "2of3") name = "2of3 with 2FA";
    if (m_type == "2of2_no_recovery") name = "AMP Account";
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
        for (auto account : m_context->getAccounts()) {
            if (account->name() == name + suffix) {
                n ++;
                retry = true;
                break;
            }
        }
    }

    auto session = m_context->getOrCreateSession(m_network);
    auto group = new TaskGroup(this);
    Task* last = nullptr;
    for (auto account : m_context->getAccounts()) {
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

        connect(create_account, &Task::failed, this, [=](const QString& error) {
            m_error = error;
        });
        connect(create_account, &Task::finished, this, [=] {
            m_account = m_context->getAccountByPointer(m_network, create_account->pointer());
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

    connect(group, &TaskGroup::finished, this, [=] {
        Q_ASSERT(m_account);
        emit created(m_account);
    });
    connect(group, &TaskGroup::failed, this, [=] {
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
    if (m_recovery_xpub.isEmpty()) {
        setError("recoveryXpub", QString{"empty"});
    } else if (!IsValidXpub(m_recovery_xpub)) {
        setError("recoveryXpub", QString{"invalid"});
    } else {
        clearError("recoveryXpub");
    }
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

QValidator::State XPubValidator::validate(QString &input, int &pos) const
{
    return IsValidXpub(input) ? QValidator::Acceptable : QValidator::Intermediate;
}
