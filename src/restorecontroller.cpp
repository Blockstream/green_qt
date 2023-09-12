#include "context.h"
#include "network.h"
#include "restorecontroller.h"
#include "wallet.h"
#include "walletmanager.h"

#include <wally_wrapper.h>

RestoreController::RestoreController(QObject *parent)
    : Controller(parent)
{
    setContext(new Context(this));
}

void RestoreController::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
    m_dispatcher->dispatch();
}

void RestoreController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged();
}

void RestoreController::setMnemonic(const QStringList& mnemonic)
{
    if (m_mnemonic == mnemonic) return;
    m_mnemonic = mnemonic;
    emit mnemonicChanged();
}

void RestoreController::setPassword(const QString& password)
{
    if (m_password == password) return;
    m_password = password;
    emit passwordChanged();
}

void RestoreController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
}

void RestoreController::setPin(const QString& pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged();
}

void RestoreController::setActive(bool active)
{
    if (m_active == active) return;
    if (m_active) return;
    m_active = active;
    emit activeChanged();

    const QJsonObject credentials({
        { "mnemonic", m_mnemonic.join(' ') },
        { "password", m_password }
    });

    auto session = m_context->getOrCreateSession(m_network);
    auto connect_task = new ConnectTask(session);
    auto mnemonic_login = new LoginTask(m_mnemonic, m_password, session);
    auto check_exists = new RestoreCheckTask(this);

    connect_task->then(mnemonic_login);
    mnemonic_login->then(check_exists);

    auto group = new TaskGroup(this);
    group->add(connect_task);
    group->add(mnemonic_login);
    group->add(check_exists);
    m_dispatcher->add(group);
}

void RestoreController::accept()
{
    auto session = m_context->getOrCreateSession(m_network);

    auto load_twofactor_config = new LoadTwoFactorConfigTask(session);
    auto load_currencies = new LoadCurrenciesTask(session);
    auto get_watchonly_details = new GetWatchOnlyDetailsTask(session);
    auto load_assets = new LoadAssetsTask(session);
    auto load_accounts = new LoadAccountsTask(true, session);

    const QJsonObject credentials({
        { "mnemonic", m_mnemonic.join(' ') },
        { "password", m_password }
    });
    auto encrypt_with_pin = new EncryptWithPinTask(credentials, m_pin, session);
    auto persist_wallet = new RestorePersistWalletTask(this);

    load_accounts->then(encrypt_with_pin);
    encrypt_with_pin->then(persist_wallet);

    auto group = new TaskGroup(this);
    group->add(load_twofactor_config);
    group->add(load_currencies);
    group->add(get_watchonly_details);
    group->add(load_assets);
    group->add(load_accounts);
    group->add(encrypt_with_pin);
    group->add(persist_wallet);
    m_dispatcher->add(group);

/*

    // TODO: context should be last
    Q_ASSERT(m_wallet->context());
    Q_ASSERT(m_wallet->m_pin_data.isEmpty());
    Q_ASSERT(!m_accepted);
    m_accepted = true;
    emit acceptedChanged();

    QJsonObject credentials({
        { "mnemonic", m_mnemonic.join(" ") },
        { "password", m_password }
    });

    auto handler = new EncryptWithPinHandler(credentials, m_pin, m_wallet->session());
    QObject::connect(handler, &Handler::done, this, [=] {
        handler->deleteLater();
    });
    handler->exec();
*/
}

void RestoreController::update()
{
//    if (m_accepted) return;
//    auto check = [this] {
//        if (!m_network) {
//            return false;
//        }
//        if (m_mnemonic.length() == 27) {
//            if (m_password.isEmpty()) return false;
//        } else if (m_mnemonic.length() == 24) {
//            if (!m_password.isEmpty()) return false;
//        } else if (m_mnemonic.length() == 12) {
//        } else {
//            return false;
//        }
//        for (auto& word : m_mnemonic) {
//            if (word.isEmpty()) return false;
//        }
//        return true;
//    };
//    if (!check()) return;

//    if (!m_active) {
//        if (m_session) {
//            // TODO: free session etc
//        }
//        return;
//    }

//    setBusy(true);

//    if (m_wallet_hash_id.isEmpty()) {
//        auto handler = new LoginHandler(m_mnemonic, m_password, m_session);
//        QObject::connect(handler, &Handler::error, this, [=] {
//            handler->deleteLater();
//            const auto error = handler->result().value("error").toString();

//            updateError("password", QStringLiteral("mismatch"), error.indexOf("Invalid checksum") >= 0);

//            setValid(false);
//            setBusy(false);
//        });
//        handler->exec();
//        return;
//    }

//    if (!m_network->isElectrum()) {
//        setBusy(false);
//        setValid(true);
//        return;
//    }

//    if (m_subaccounts.isEmpty()) {
//        auto handler = new GetSubAccountsHandler(m_session, true);
//        QObject::connect(handler, &Handler::done, this, [=] {
//            handler->deleteLater();
//            m_subaccounts = handler->subAccounts();
//            update();
//        });
//        handler->exec();
//        return;
//    }

//    for (auto subaccount : m_subaccounts) {
//        if (subaccount.toObject().value("bip44_discovered").toBool()) {
//            setValid(true);
//            break;
//        }
//    }

//    setBusy(false);
}

void RestoreController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged();
}

RestoreCheckTask::RestoreCheckTask(RestoreController* controller)
    : Task(controller->dispatcher())
    , m_controller(controller)
{
}

void RestoreCheckTask::update()
{
    if (status() != Status::Ready) return;

    const auto context = m_controller->context();
    const auto wallet_hash_id = context->m_wallet_hash_id;
    if (wallet_hash_id.isEmpty()) return;

    setStatus(Status::Active);

    const auto wallet = WalletManager::instance()->walletWithHashId(wallet_hash_id, false);

    m_controller->setWallet(wallet);
    m_controller->setValid(!wallet || !wallet->hasPinData());
    context->setWallet(wallet);

    setStatus(Status::Finished);
}

RestorePersistWalletTask::RestorePersistWalletTask(RestoreController *controller)
    : Task(controller->dispatcher())
    , m_controller(controller)
{
}

void RestorePersistWalletTask::update()
{
    if (status() != Status::Ready) return;

    setStatus(Status::Active);

    const auto context = m_controller->context();
    const auto network = m_controller->network();
    const auto wallet_hash_id = context->m_wallet_hash_id;
    auto wallet = m_controller->wallet();

    if (!wallet) {
        wallet = WalletManager::instance()->restoreWallet(network, wallet_hash_id);
        if (m_controller->type() == "amp") {
            wallet->setName(WalletManager::instance()->uniqueWalletName("My AMP Wallet"));
        } else {
            wallet->setName(WalletManager::instance()->newWalletName(network));
        }
    }
    wallet->m_login_attempts_remaining = 3;
    wallet->m_pin_data = QJsonDocument(context->m_pin_data).toJson();

    context->setWallet(wallet);
    wallet->setContext(context);
    context->refresh();
    m_controller->setWallet(wallet);

    WalletManager::instance()->insertWallet(wallet);

    setStatus(Status::Finished);

    emit m_controller->walletRestored(wallet);
}
