#include "account.h"
#include "context.h"
#include "network.h"
#include "networkmanager.h"
#include "restorecontroller.h"
#include "wallet.h"
#include "walletmanager.h"

#include <wally_wrapper.h>

RestoreController::RestoreController(QObject *parent)
    : Controller(parent)
{
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

//void RestoreController::setWallet(Wallet* wallet)
//{
//    if (m_wallet == wallet) return;
//    m_wallet = wallet;
//    emit walletChanged();
//}

//void RestoreController::setPin(const QString& pin)
//{
//    if (m_pin == pin) return;
//    m_pin = pin;
//    emit pinChanged();
//}

//void RestoreController::setActive(bool active)
//{
//    if (m_active == active) return;
//    if (m_active) return;
//    m_active = active;
//    emit activeChanged();

//    const QJsonObject credentials({
//        { "mnemonic", m_mnemonic.join(' ') },
//        { "password", m_password }
//    });

//    auto session = m_context->getOrCreateSession(m_network);
//    auto connect_task = new ConnectTask(session);
//    auto mnemonic_login = new LoginTask(m_mnemonic, m_password, session);
//    auto check_exists = new RestoreCheckTask(this);

//    connect_task->then(mnemonic_login);
//    mnemonic_login->then(check_exists);

//    auto group = new TaskGroup(this);
//    group->add(connect_task);
//    group->add(mnemonic_login);
//    group->add(check_exists);
//    m_dispatcher->add(group);
//}

void RestoreController::restore()
{
    if (m_context) m_context->deleteLater();
    setContext(new Context(this));

    auto monitor = new TaskGroupMonitor(this);
    connect(monitor, &TaskGroupMonitor::allFinishedOrFailed, this, [=] {
        auto context = m_context;
        setContext(nullptr);

        // TODO: check if wallet already exists
        auto wallet = WalletManager::instance()->createWallet();
        wallet->setName(WalletManager::instance()->newWalletName());
        // TODO: new pin data, reset login attempts
        // wallet->m_login_attempts_remaining = 3;
        // wallet->m_pin_data = QJsonDocument(context->m_pin_data).toJson();

        context->setWallet(wallet);
        wallet->setContext(context);

        WalletManager::instance()->insertWallet(wallet);

        emit restoreFinished(context);
    });

    for (auto network : NetworkManager::instance()->networks()) {
        if (network->isMainnet()) {
            auto group = check(network);
            monitor->add(group);
        }
    }
}

TaskGroup* RestoreController::check(Network* network)
{
    auto group = new TaskGroup(this);

    auto session = m_context->getOrCreateSession(network);
    auto connect_session = new ConnectTask(session);
    auto login = new LoginTask(m_mnemonic, m_password, session);

    group->add(connect_session);
    group->add(login);

    if (network->isElectrum()) {
        auto load_accounts = new LoadAccountsTask(true, session);
        group->add(load_accounts);
    }

    m_context->dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, [=] {
        m_context->releaseSession(session);
    });

    return group;
}

//void RestoreController::update()
//{
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
//}

//void RestoreController::setValid(bool valid)
//{
//    if (m_valid == valid) return;
//    m_valid = valid;
//    emit validChanged();
//}

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

//    m_controller->setWallet(wallet);
//    m_controller->setValid(!wallet || !wallet->hasPinData());
    context->setWallet(wallet);

    setStatus(Status::Finished);
}
