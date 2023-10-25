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
    Q_ASSERT(m_valid);
    setContext(new Context(this));
    m_context->setWatchonly(true);

    auto session = m_context->getOrCreateSession(m_network);

    auto connect_session = new ConnectTask(session);
    auto session_login = new LoginTask(m_username, m_password, session);
    auto create_wallet = new WatchOnlyCreateWalletTask(this);

//    context->setWallet(m_wallet);

    connect_session->then(session_login);
    session_login->then(create_wallet);

    auto group = new TaskGroup(this);

    group->add(connect_session);
    group->add(session_login);
    group->add(create_wallet);

    m_dispatcher->add(group);

    connect(group, &TaskGroup::finished, this, &WatchOnlyLoginController::loginFinished);
    connect(group, &TaskGroup::failed, this, &WatchOnlyLoginController::loginFailed);
    connect(group, &TaskGroup::failed, m_context, &QObject::deleteLater);
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
    const auto xpub_hash_id = context->xpubHashId();
    if (xpub_hash_id.isEmpty()) return;

    setStatus(Status::Active);

    auto wallet = m_controller->wallet();
    if (!wallet) {
        auto wallet = WalletManager::instance()->findWallet(xpub_hash_id, true);
        if (!wallet) {
            wallet = WalletManager::instance()->createWallet();
            wallet->setName(QString("%1 watch-only wallet").arg(m_controller->username()));
            wallet->m_username = m_controller->username();
            wallet->m_watch_only = true;
            wallet->m_is_persisted = m_controller->saveWallet();
        }
        context->setWallet(wallet);
        wallet->setContext(context);
        wallet->save();
    }
    m_controller->setWallet(wallet);

    setStatus(Status::Finished);
}
