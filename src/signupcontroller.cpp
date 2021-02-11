#include "ga.h"
#include "signupcontroller.h"
#include "wallet.h"
#include "walletmanager.h"

SignupController::SignupController(QObject *parent) : QObject(parent)
{
    m_mnemonic = GA::generate_mnemonic();
}

QStringList SignupController::mnemonic() const
{
    return m_mnemonic;
}

Network *SignupController::network() const
{
    return m_network;
}

void SignupController::setNetwork(Network *network)
{
    if (m_network == network) return;
    m_network = network;
    if (m_network) {
        setDefaultName(WalletManager::instance()->newWalletName(m_network));
    }
    emit networkChanged(m_network);
}

QString SignupController::defaultName() const
{
    return m_defaultName;
}

QString SignupController::name() const
{
    return m_name;
}

Wallet *SignupController::wallet() const
{
    return m_wallet;
}

void SignupController::signup(const QString &proxy, bool use_tor, const QByteArray& pin)
{
    Q_ASSERT(!m_wallet);
    m_wallet = WalletManager::instance()->signup(proxy, use_tor, m_network, m_name.isEmpty() ? m_defaultName : m_name, m_mnemonic, pin);
    emit walletChanged(m_wallet);

    connect(m_wallet, &Wallet::authenticationChanged, this, [this] {
        if (m_wallet->authentication() == Wallet::Authenticated) {
            emit done();
        }
    });
}

void SignupController::setDefaultName(const QString &default_name)
{
    if (m_defaultName == default_name) return;
    m_defaultName = default_name;
    emit defaultNameChanged(m_defaultName);
}

void SignupController::setName(const QString &name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged(m_name);
}
