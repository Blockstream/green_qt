#include "loginhandler.h"
#include "network.h"
#include "networkmanager.h"
#include "walletmanager.h"
#include "watchonlylogincontroller.h"

#include <gdk.h>

WatchOnlyLoginController::WatchOnlyLoginController(QObject* parent)
    : Entity(parent)
{
}

void WatchOnlyLoginController::setNetwork(Network *network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged(m_network);
    void updateValid();
}

void WatchOnlyLoginController::setUsername(const QString &username)
{
    if (m_username == username) return;
    m_username = username;
    emit usernameChanged(m_username);
    updateValid();
}

void WatchOnlyLoginController::setPassword(const QString &password)
{
    if (m_password == password) return;
    m_password = password;
    emit passwordChanged(m_password);
    updateValid();
}

void WatchOnlyLoginController::updateValid()
{
    setValid(m_network && !m_network->isLiquid() && !m_username.isEmpty() && !m_password.isEmpty());

}
void WatchOnlyLoginController::login()
{
    if (!m_valid) return;
    if (!m_wallet) {
        m_wallet = WalletManager::instance()->createWallet(m_network);
        m_wallet->m_watch_only = true;
        m_wallet->m_username = m_username;
        m_wallet->createSession();

        m_session = m_wallet->session();
        emit sessionChanged(m_session);

        m_wallet.track(QObject::connect(m_session, &Session::activityCreated, this, &WatchOnlyLoginController::activityCreated));
        m_wallet.track(QObject::connect(m_session, &Session::connectedChanged, this, [this] {
            if (!m_wallet->session()->isConnected()) return;

            auto handler = new LoginHandler(m_wallet, m_username, m_password);
            handler->connect(handler, &Handler::done, this, [this, handler] {
                handler->deleteLater();
                m_wallet->updateHashId(handler->walletHashId());
                emit walletChanged(m_wallet);
                m_wallet->setSession();
                WalletManager::instance()->addWallet(m_wallet);
            });
            handler->connect(handler, &Handler::error, this, [this, handler] {
                handler->deleteLater();
                m_wallet->deleteLater();
                m_session = nullptr;
                emit sessionChanged(m_session);
                emit unauthorized();
            });
            handler->exec();
        }));
        m_wallet->session()->setActive(true);
    }
}

void WatchOnlyLoginController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged(m_valid);
}
