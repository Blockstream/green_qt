#include "ga.h"
#include "signupcontroller.h"
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
    if (!m_network.update(network)) return;
    emit networkChanged(m_network);
    setDefaultName(m_network ? WalletManager::instance()->newWalletName(m_network) : "");
    update();
}

void SignupController::setType(const QString& type)
{
    Q_ASSERT(type.isEmpty() || type == "amp");
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
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

void SignupController::update()
{
    if (!m_active) return;
    if (m_pin.isEmpty()) return;

    if (!m_wallet) {
        m_wallet = WalletManager::instance()->createWallet();
        m_wallet->m_network = m_network;
        m_wallet->m_name = m_name.isEmpty() ? m_defaultName : m_name;
        emit walletChanged(m_wallet);

        m_wallet->createSession();
        m_session = m_wallet->session();
        m_session.track(QObject::connect(m_session, &Session::connectedChanged, this, &SignupController::update));

        m_session->setActive(true);
    }

    if (!m_session->isConnected()) return;

    m_wallet->signup(m_mnemonic, m_pin);
    // TODO: should only add if signup completes
    WalletManager::instance()->addWallet(m_wallet);
}

void SignupController::setPin(const QByteArray &pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged(m_pin);
    update();
}

void SignupController::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged(m_active);
    update();
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
    update();
}
