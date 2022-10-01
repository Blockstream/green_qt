#include "controller.h"

#include <gdk.h>

#include "device.h"
#include "handler.h"
#include "json.h"
#include "output.h"
#include "resolver.h"
#include "session.h"
#include "wallet.h"

class SetUnspentOutputsStatusHandler : public Handler
{
    QVariantList m_outputs;
    QString m_status;
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        QJsonArray list;
        for (const auto &output : m_outputs)
        {
            QJsonObject o;
            o["txhash"] = output.value<Output*>()->data()["txhash"].toString();
            o["pt_idx"] = output.value<Output*>()->data()["pt_idx"].toInt();
            o["user_status"] = m_status;
            list.append(o);
        }
        auto details = Json::fromObject({
            { "list", list }
        });

        int err = GA_set_unspent_outputs_status(session, details.get(), auth_handler);
        Q_ASSERT(err == GA_OK);
    }
public:
    SetUnspentOutputsStatusHandler(const QVariantList &outputs, const QString &status, Session* session)
        : Handler(session),
        m_outputs(outputs),
        m_status(status)
    {
    }
};

class DisableAllPinLoginsHandler : public Handler
{
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        Q_UNUSED(auth_handler)
        int err = GA_disable_all_pin_logins(session);
        Q_ASSERT(err == GA_OK);
    }
public:
    DisableAllPinLoginsHandler(Session* session)
        : Handler(session)
    {
    }
};

class ChangeSettingsHandler : public Handler
{
    QJsonObject m_data;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto data = Json::fromObject(m_data);
        int err = GA_change_settings(session, data.get(), auth_handler);
        Q_ASSERT(err == GA_OK);
    }
public:
    ChangeSettingsHandler(const QJsonObject& data, Session* session)
        : Handler(session)
        , m_data(data)
    {
    }
};

class SendNLocktimesHandler : public Handler
{
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        Q_UNUSED(auth_handler);
        int err = GA_send_nlocktimes(session);
        // Can't Q_ASSERT(err == GA_OK) because err != GA_OK
        // if no utxos found (e.g. new wallet)
        Q_UNUSED(err);
    }
public:
    SendNLocktimesHandler(Session* session)
        : Handler(session)
    {
    }
};

class ChangeSettingsTwoFactorHandler : public Handler
{
    QByteArray m_method;
    QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto details = Json::fromObject(m_details);
        int res = GA_change_settings_twofactor(session, m_method.data(), details.get(), auth_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    ChangeSettingsTwoFactorHandler(const QByteArray& method, const QJsonObject& details, Session* session)
        : Handler(session)
        , m_method(method)
        , m_details(details)
    {
    }
};

class TwoFactorChangeLimitsHandler : public Handler
{
    QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto details = Json::fromObject(m_details);
        GA_twofactor_change_limits(session, details.get(), auth_handler);
    }
public:
    TwoFactorChangeLimitsHandler(const QJsonObject& details, Session* session)
        : Handler(session)
        , m_details(details)
    {
    }
};

class TwoFactorCancelResetHandler : public Handler
{
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        int res = GA_twofactor_cancel_reset(session, auth_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    TwoFactorCancelResetHandler(Session* session)
        : Handler(session)
    {
    }
};

class SetCsvTimeHandler : public Handler
{
    const int m_value;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto details = Json::fromObject({{ "value", m_value }});
        int res = GA_set_csvtime(session, details.get(), auth_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    SetCsvTimeHandler(const int value, Session* session)
        : Handler(session)
        , m_value(value)
    {
    }
};

AbstractController::AbstractController(QObject* parent)
    : Entity(parent)
{
}

bool AbstractController::updateError(const QString &key, const QVariant &value, bool when)
{
    if (when) {
        setError(key, value);
        return true;
    } else {
        clearError(key);
        return false;
    }
}

void AbstractController::setError(const QString &key, const QVariant &value)
{
    Q_ASSERT(!value.isNull());
    if (m_errors.contains(key) && m_errors.value(key) == value) return;
    m_errors[key] = value;
    emit errorsChanged();
}

void AbstractController::clearError(const QString &key)
{
    if (!m_errors.contains(key)) return;
    m_errors.remove(key);
    emit errorsChanged();
}

void AbstractController::clearErrors()
{
    if (m_errors.empty()) return;
    m_errors.clear();
    emit errorsChanged();
}

Controller::Controller(QObject* parent)
    : AbstractController(parent)
{
}

void Controller::exec(Handler* handler)
{
    // TODO get xpubs should be delegated
    connect(handler, &Handler::done, this, [this, handler] { emit done(handler); });
    connect(handler, &Handler::error, this, [this, handler] { emit error(handler); });
    connect(handler, &Handler::requestCode, this, [this, handler] { emit requestCode(handler); });
    connect(handler, &Handler::invalidCode, this, [this, handler] { emit invalidCode(handler); });
    connect(handler, &Handler::resolver, this, &Controller::resolver);
    connect(handler, &Handler::deviceRequested, this, [=] { emit deviceRequested(handler); });
    handler->exec();
}

GA_session* Controller::session() const
{
    return m_wallet ? m_wallet->m_session->m_session : nullptr;
}

Wallet* Controller::wallet() const
{
    return m_wallet;
}

void Controller::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged(m_wallet);
}

void Controller::changeSettings(const QJsonObject& data)
{
    if (!m_wallet) return;

    // Avoid unnecessary calls to GA_change_settings
    bool updated = true;
    auto settings = m_wallet->settings();
    for (auto i = data.begin(); i != data.end(); ++i) {
        if (settings.value(i.key()) != i.value()) {
            updated = false;
            settings[i.key()] = i.value();
        }
    }
    if (updated) return;

    // Check if wallet is undergoing reset
    if (m_wallet->isLocked()) {
        qDebug() << Q_FUNC_INFO << "wallet is locked";
        return;
    }

    auto handler = new ChangeSettingsHandler(settings, m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        m_wallet->updateSettings();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::sendRecoveryTransactions()
{
    if (!m_wallet) return;
    auto handler = new SendNLocktimesHandler(m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        m_wallet->updateSettings();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::enableTwoFactor(const QString& method, const QString& data)
{
    if (!m_wallet) return;
    auto details = QJsonObject{
        { "data", data },
        { "enabled", true }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method.toLatin1(), details, m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        m_wallet->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::disableTwoFactor(const QString& method)
{
    if (!m_wallet) return;
    auto details = QJsonObject{
        { "enabled", false }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method.toLatin1(), details, m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        m_wallet->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::changeTwoFactorLimit(bool is_fiat, const QString& limit)
{
    if (!m_wallet) return;
    auto unit = is_fiat ? "fiat" : m_wallet->settings().value("unit").toString().toLower();
    if (!is_fiat && unit == "\u00B5btc") unit = "ubtc";
    auto details = QJsonObject{
        { "is_fiat", is_fiat },
        { unit, limit }
    };
    auto handler = new TwoFactorChangeLimitsHandler(details, m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        m_wallet->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::requestTwoFactorReset(const QString& email)
{
    if (!m_wallet) return;
    auto handler = new TwoFactorResetHandler(email.toLatin1(), m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        m_wallet->updateConfig();
        // TODO: updateConfig doesn't update 2f reset data,
        // it's only updated after authentication in GDK,
        // so force wallet lock for now.
        m_wallet->setLocked(true);
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::cancelTwoFactorReset()
{
    if (!m_wallet) return;
    auto handler = new TwoFactorCancelResetHandler(m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        m_wallet->updateConfig();
        // TODO: updateConfig doesn't update 2f reset data,
        // it's only updated after authentication in GDK,
        // so force wallet unlock for now.
        m_wallet->setLocked(false);
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::setRecoveryEmail(const QString& email)
{
    if (!m_wallet) return;
    const auto method = QByteArray{"email"};
    const auto details = QJsonObject{
        { "data", email.toLatin1().data() },
        { "confirmed", true },
        { "enabled", false }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method, details, m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();
        m_wallet->updateConfig();
    });
    connect(handler, &Handler::done, this, [this] {
        auto details = QJsonObject{
            { "notifications" , QJsonValue({
                { "email_incoming", true },
                { "email_outgoing", true }})
            }
        };
        auto handler = new ChangeSettingsHandler(details, m_wallet->session());
        connect(handler, &Handler::done, this, [this, handler] {
            handler->deleteLater();
            emit finished();
        });
        exec(handler);
    });
    exec(handler);
}

void Controller::setCsvTime(int value)
{
    const auto handler = new SetCsvTimeHandler(value, m_wallet->session());
    connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();
        m_wallet->updateSettings();
        emit finished();
    });
    exec(handler);
}

#include "deletewallethandler.h"
#include "walletmanager.h"
void Controller::deleteWallet()
{
    auto handler = new DeleteWalletHandler(m_wallet->session());
    connect(handler, &Handler::done, [this, handler] {
        handler->deleteLater();
        m_wallet->disconnect();
        WalletManager::instance()->removeWallet(m_wallet);
    });
    connect(handler, &Handler::error, [handler] {
        handler->deleteLater();
    });
    exec(handler);
}

void Controller::disableAllPins()
{
    auto handler = new DisableAllPinLoginsHandler(m_wallet->session());
    QObject::connect(handler, &Handler::done, [this, handler] {
        m_wallet->clearPinData();
        handler->deleteLater();
    });
    connect(handler, &Handler::error, [handler] {
        handler->deleteLater();
    });
    exec(handler);
}

void Controller::setUnspentOutputsStatus(const QVariantList &outputs, const QString &status)
{
    auto handler = new SetUnspentOutputsStatusHandler(outputs, status, m_wallet->session());
    QObject::connect(handler, &Handler::done, [this, handler] {
        handler->deleteLater();
        emit finished();
    });
    connect(handler, &Handler::error, [handler] {
        handler->deleteLater();
    });
    exec(handler);
}

Handler* Controller::getCredentials()
{
    auto handler = new GetCredentialsHandler(m_wallet->session());
    QObject::connect(handler, &Handler::done, [this, handler] {
        emit finished(handler);
    });
    exec(handler);
    handler->setParent(this);
    return handler;
}

void TwoFactorResetHandler::call(GA_session *session, GA_auth_handler **auth_handler) {
    const uint32_t is_dispute = GA_FALSE;
    int res = GA_twofactor_reset(session, m_email.data(), is_dispute, auth_handler);
    Q_ASSERT(res == GA_OK);
}

TwoFactorResetHandler::TwoFactorResetHandler(const QByteArray &email, Session *session)
    : Handler(session)
    , m_email(email)
{
}

ChangePinController::ChangePinController(QObject* parent)
    : Controller(parent)
{
}

void ChangePinController::setPin(const QString& pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged();
}

void ChangePinController::accept()
{
    if (m_credentials.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "retrieving credentials";
        auto handler = new GetCredentialsHandler(wallet()->session());
        connect(handler, &Handler::done, this, [=] {
            handler->deleteLater();
            m_credentials = handler->credentials();
            accept();
        });
        exec(handler);
    } else {
        qDebug() << Q_FUNC_INFO << "encrypting credentials with new PIN";
        auto handler = new EncryptWithPinHandler(m_credentials, m_pin, wallet()->session());
        connect(handler, &Handler::done, this, [=] {
            handler->deleteLater();
            auto pin_data = handler->pinData();
            wallet()->setPinData(pin_data);
            emit finished();
        });
        exec(handler);
    }
}
