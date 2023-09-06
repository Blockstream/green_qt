#include "watchonlylogincontroller.h"

#include <gdk.h>

#include "context.h"
#include "network.h"
#include "task.h"
#include "wallet.h"
#include "walletmanager.h"

WatchOnlyLoginController::WatchOnlyLoginController(QObject* parent)
    : Controller(parent)
{
//    new WatchOnlyCreateWalletTask(this);

//    connect(m_dispatcher, &TaskDispatcher::finished, this, [=] {
//        if (m_wallet) {
//            m_wallet->setContext(m_context);
//            WalletManager::instance()->addWallet(m_wallet);
//            setWallet(nullptr);
//        }
//    });

//    connect(this, &LoginController::walletChanged, this, [=] {
//        if (m_wallet && m_wallet->isWatchOnly()) {
//            setUsername(m_wallet->username());
//            setNetwork(m_wallet->network());
//        }
//        updateValid();
//    });
}

void WatchOnlyLoginController::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
    void update();
}

void WatchOnlyLoginController::setUsername(const QString& username)
{
    if (m_username == username) return;
    m_username = username;
    emit usernameChanged();
    update();
}

void WatchOnlyLoginController::setPassword(const QString& password)
{
    if (m_password == password) return;
    m_password = password;
    emit passwordChanged();
    update();
}

void WatchOnlyLoginController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
    if (m_context) m_context->setWallet(wallet);
    update();
}

void WatchOnlyLoginController::setSaveWallet(bool save_wallet)
{
    if (m_save_wallet == save_wallet) return;
    m_save_wallet = save_wallet;
    emit saveWalletChanged();
}

void WatchOnlyLoginController::update()
{
    setValid(m_network && !m_username.isEmpty() && !m_password.isEmpty());
}

void WatchOnlyLoginController::login()
{
    if (m_valid) {
        auto context = new Context(this);
        context->setWallet(m_wallet);
        context->setWatchonly(true);
        setContext(context);

        auto session = context->getOrCreateSession(m_network);
        auto connect_session = new ConnectTask(session);
        auto session_login = new LoginTask(m_username, m_password, session);
        auto create_wallet = new WatchOnlyCreateWalletTask(this);

        connect_session->then(session_login);
        session_login->then(create_wallet);

        auto group = new TaskGroup(this);

        group->add(connect_session);
        group->add(session_login);
        group->add(create_wallet);
        m_dispatcher->add(group);

        connect(group, &TaskGroup::finished, this, &WatchOnlyLoginController::load);
        connect(group, &TaskGroup::failed, this, &WatchOnlyLoginController::loginFailed);
    }
}

void WatchOnlyLoginController::load()
{
    auto group = new TaskGroup(this);

    auto session = m_context->getOrCreateSession(m_network);

    group->add(new LoadCurrenciesTask(session));
    if (m_network->isLiquid()) group->add(new LoadAssetsTask(session));
    group->add(new LoadAccountsTask(false, session));
    m_dispatcher->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        m_wallet->setContext(m_context);
        m_context->refreshAccounts();
        WalletManager::instance()->addWallet(m_wallet);
        emit loginFinished(m_wallet);
    });
}

void WatchOnlyLoginController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged();
}


WatchOnlyCreateWalletTask::WatchOnlyCreateWalletTask(WatchOnlyLoginController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void WatchOnlyCreateWalletTask::update()
{
    if (m_status != Status::Ready) return;

    const auto context = m_controller->context();
    const auto wallet_hash_id = context->m_wallet_hash_id;

    if (wallet_hash_id.isEmpty()) return;

    setStatus(Status::Active);

    auto wallet = m_controller->wallet();
    if (!wallet) {
        const auto network = m_controller->network();

        wallet = WalletManager::instance()->walletWithHashId(wallet_hash_id, true);
        if (!wallet) {
            wallet = WalletManager::instance()->createWallet(network, wallet_hash_id);
            wallet->m_watch_only = true;
            wallet->m_is_persisted = m_controller->saveWallet();
            wallet->m_name = QString("%1 watch-only wallet").arg(m_controller->username());
        }
        wallet->m_username = m_controller->username();
        wallet->save();
    }
    m_controller->setWallet(wallet);

    setStatus(Status::Finished);
}
/*
void WatchOnlyCreateWalletTask::load()
{
    auto group = new TaskGroup(this);
    group->add(new GetWatchOnlyDetailsTask(m_context));
    group->add(new LoadTwoFactorConfigTask(m_context));
    group->add(new LoadCurrenciesTask(m_context));
    if (m_wallet->network()->isLiquid()) group->add(new LoadAssetsTask(m_context));
    group->add(new LoadAccountsTask(m_context));
    m_dispatcher->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        WalletManager::instance()->addWallet(m_wallet);
        m_wallet->setContext(m_context);
        emit loginFinished(m_wallet);
    });

    connect(group, &TaskGroup::failed, this, [=] {
        emit loginFailed();
    });
}
*/
