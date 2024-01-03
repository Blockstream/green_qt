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

void CreateAccountController::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();

    clearError("create");
    updateError("name", QString{"empty"}, m_name.isEmpty());
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

    if (m_name.isEmpty()) {
        QString name;
        if (m_type == "2of2" || m_type == "2of3") {
            name = "2FA Protected";
        }
        if (m_type == "2of2_no_recovery") {
            name = "AMP Account";
        }
        if (m_type == "p2wpkh") {
            name = "Standard";
        }
        if (m_type == "p2sh-p2wpkh") {
            name = "Legacy SegWit";
        }
        if (m_type == "p2pkh") {
            name = "Legacy";
        }
        setName(m_network->isLiquid() ? name + " Liquid" : name);
    }

    auto monitor = new TaskGroupMonitor(this);
    setMonitor(monitor);

    if (m_network->isElectrum()) {
        for (auto account : m_context->getAccounts()) {
            if (account->network() != m_network) continue;
            if (account->type() != m_type) continue;
            if (account->pointer() > 0) continue;
            if (account->json().value("bip44_discovered").toBool()) continue;
            if (!account->name().isEmpty()) continue;
            if (!account->synced()) continue;

            m_account = account;
            m_account->setName(m_name);
            auto update_task = new UpdateAccountTask({{ "name", m_name }}, m_account->session());
            auto group = new TaskGroup(this);
            group->add(update_task);
            monitor->add(group);
            dispatcher()->add(group);
            connect(group, &TaskGroup::finished, this, [=] {
                emit created(m_account);
            });
            return;
        }
    }

    auto details = QJsonObject{
        { "name", m_name },
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

    auto session = m_context->getOrCreateSession(m_network);

    auto session_connect = new ConnectTask(session);
    auto session_register = session->registerUser();
    auto session_login = session->login();

    auto create_account = new CreateAccountTask(details, session);
    auto load_accounts = new LoadAccountsTask(false, session);

    session_register->then(session_login);
    session_login->then(create_account);
    create_account->then(load_accounts);

    auto group = new TaskGroup(this);

    group->add(session_connect);
    group->add(session_register);
    group->add(session_login);
    group->add(create_account);
    group->add(load_accounts);

    monitor->add(group);
    dispatcher()->add(group);

    connect(create_account, &Task::failed, this, [=](const QString& error) {
        setError("create", error);
    });

    connect(group, &TaskGroup::finished, this, [=] {
        m_account = m_context->getAccountByPointer(m_network, create_account->pointer());
        if (!m_account) return;
        emit created(m_account);
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
