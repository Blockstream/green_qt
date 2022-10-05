#include "watchonlylogincontroller.h"

#include <gdk.h>

#include "loginhandler.h"
#include "network.h"
#include "session.h"
#include "wallet.h"
#include "walletmanager.h"

WatchOnlyLoginController::WatchOnlyLoginController(QObject* parent)
    : Entity(parent)
{
}

void WatchOnlyLoginController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged(m_wallet);
    if (m_wallet) {
        Q_ASSERT(wallet->isWatchOnly());
        setUsername(m_wallet->username());
        setNetwork(m_wallet->network());
    }
    updateValid();
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

void WatchOnlyLoginController::setSaveWallet(bool save_wallet)
{
    if (m_save_wallet == save_wallet) return;
    m_save_wallet = save_wallet;
    emit saveWalletChanged(m_save_wallet);
}

void WatchOnlyLoginController::updateValid()
{
    setValid(m_network && !m_username.isEmpty() && !m_password.isEmpty());
}

void WatchOnlyLoginController::login()
{
    if (!m_valid) return;

    if (!m_session) {
        m_session = new Session(m_network, this);

        m_session.track(connect(m_session, &Session::connectedChanged, this, &WatchOnlyLoginController::login));
        m_session.track(connect(m_session, &Session::activityCreated, this, &WatchOnlyLoginController::activityCreated));

        m_session->setActive(true);

        emit sessionChanged(m_session);
        return;
    }

    if (m_session->isActive() && !m_session->isConnected()) return;

    auto handler = new LoginHandler(m_username, m_password, m_session);
    handler->connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();

        if (!m_wallet) {
            m_wallet = WalletManager::instance()->createWallet(m_network, handler->walletHashId());
            m_wallet->m_watch_only = true;
            m_wallet->m_username = m_username;
            m_wallet->m_is_persisted = m_save_wallet;
            m_wallet->m_name = QString("%1 watch-only wallet").arg(m_username);
            emit walletChanged(m_wallet);
        }
        m_wallet->setSession(m_session);
        m_wallet->setSession();
        m_session->setParent(m_wallet);
        m_session = nullptr;
        WalletManager::instance()->addWallet(m_wallet);
        emit loginDone();
    });
    handler->connect(handler, &Handler::error, this, [this, handler] {
        handler->deleteLater();
        m_session->deleteLater();
        m_session = nullptr;
        emit sessionChanged(m_session);
        emit unauthorized();
    });
    handler->exec();
}

void WatchOnlyLoginController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged(m_valid);
}
