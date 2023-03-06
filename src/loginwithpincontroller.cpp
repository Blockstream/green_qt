#include "loginwithpincontroller.h"

#include "loginhandler.h"
#include "wallet.h"

LoginWithPinController::LoginWithPinController(QObject* parent)
    : Entity(parent)
{
}

void LoginWithPinController::setWallet(Wallet* wallet)
{
    if (!m_wallet.update(wallet)) return;
    emit walletChanged();
    update();
}

void LoginWithPinController::setPin(const QString& pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged();
    update();
}

void LoginWithPinController::update()
{
    if (!m_wallet) return;
    if (m_wallet->m_login_attempts_remaining == 0) return;
    if (m_pin.isEmpty()) return;
    if (m_wallet->m_pin_data.isEmpty()) return;

    auto session = m_wallet->session();
    if (!session) {
        m_wallet->createSession();
        session = m_wallet->session();
    }
    if (m_session.update(session)) {
        m_session.track(QObject::connect(m_session, &Session::connectedChanged, this, &LoginWithPinController::update));
    }
    if (!m_session->isActive()) {
        m_session->setActive(true);
        return;
    }
    if (!m_session->isConnected()) return;

    m_wallet->setAuthentication(Wallet::Authenticating);

    auto pin_data = QJsonDocument::fromJson(m_wallet->m_pin_data).object();
    auto handler = new LoginHandler(pin_data, m_pin, m_session);
    handler->connect(handler, &Handler::done, this, [=] {
        handler->deleteLater();
        m_wallet->resetLoginAttempts();
        m_wallet->updateHashId(handler->walletHashId());
        m_wallet->setAuthentication(Wallet::Authenticated);
        m_wallet->updateCurrencies();
        m_wallet->updateSettings();
        m_wallet->reload();
        m_wallet->updateConfig();
        emit loginDone();
    });
    handler->connect(handler, &Handler::error, this, [=] {
        handler->deleteLater();
        const auto error = handler->result().value("error").toString();
        if (error == "id_invalid_pin") {
            m_wallet->setAuthentication(Wallet::Unauthenticated);
            m_wallet->decrementLoginAttempts();
        }
        if (error.contains("exception:reconnect required")) {
            m_wallet->setAuthentication(Wallet::Unauthenticated);
            return;
        }
        qWarning() << "unhandled login_with_pin error";
        emit loginFailed();
    });
    handler->exec();
}
