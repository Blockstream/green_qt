#include "restorecontroller.h"
#include "wallet.h"
#include "walletmanager.h"

RestoreController::RestoreController(QObject *parent)
    : QObject(parent)
{
}

Network* RestoreController::network() const
{
    return m_network;
}

void RestoreController::setNetwork(Network* network)
{
    if (m_network == network) return;
    if (m_network) {
        Q_ASSERT(network);
        emit walletChanged(nullptr);
        m_wallet = nullptr;
        delete m_wallet;
    }
    m_network = network;
    if (network) {
        m_wallet = WalletManager::instance()->createWallet();
        emit walletChanged(m_wallet);
        m_wallet->setNetwork(network);
        m_default_name = WalletManager::instance()->newWalletName(m_network);
    } else {
        m_default_name.clear();
    }
    emit networkChanged(m_network);
    emit defaultNameChanged(m_default_name);
}

QString RestoreController::defaultName() const
{
    return m_default_name;
}

QString RestoreController::name() const
{
    return m_name;
}

void RestoreController::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    if (m_wallet) {
        Q_ASSERT(m_network && !m_default_name.isEmpty());
        m_wallet->setName(m_name.isEmpty() ? m_default_name : m_name);
    }
    emit nameChanged(m_name);
}

Wallet* RestoreController::wallet() const
{
    return m_wallet;
}

void RestoreController::restore()
{
    if (m_name.isEmpty()) {
        Q_ASSERT(!m_default_name.isEmpty());
        setName(m_default_name);
    }
    WalletManager::instance()->insertWallet(m_wallet);
}
