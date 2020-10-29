#include "controller.h"
#include "device.h"
#include "handler.h"
#include "json.h"
#include "resolver.h"
#include "wallet.h"

#include <gdk.h>

class ChangeSettingsHandler : public Handler
{
    QJsonObject m_data;
    void init(GA_session* session) override {
        auto data = Json::fromObject(m_data);
        int err = GA_change_settings(session, data, &m_handler);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(data);
        Q_ASSERT(err == GA_OK);
    }
public:
    ChangeSettingsHandler(const QJsonObject& data, Wallet* wallet)
        : Handler(wallet)
        , m_data(data)
    {
    }
};


class SendNLocktimesHandler : public Handler
{
    void init(GA_session* session) override {
        int err = GA_send_nlocktimes(session);
        // Can't Q_ASSERT(err == GA_OK) because err != GA_OK
        // if no utxos found (e.g. new wallet)
        Q_UNUSED(err);
    }
public:
    SendNLocktimesHandler(Wallet* wallet)
        : Handler(wallet)
    {
    }
};

class ChangeSettingsTwoFactorHandler : public Handler
{
    QByteArray m_method;
    QJsonObject m_details;
    void init(GA_session* session) override {
        auto details = Json::fromObject(m_details);
        int res = GA_change_settings_twofactor(session, m_method.data(), details, &m_handler);
        Q_ASSERT(res == GA_OK);
        res = GA_destroy_json(details);
        Q_ASSERT(res == GA_OK);
    }
public:
    ChangeSettingsTwoFactorHandler(const QByteArray& method, const QJsonObject& details, Wallet* wallet)
        : Handler(wallet)
        , m_method(method)
        , m_details(details)
    {
    }
};

class TwoFactorChangeLimitsHandler : public Handler
{
    QJsonObject m_details;
    void init(GA_session* session) override {
        auto details = Json::fromObject(m_details);
        int err = GA_twofactor_change_limits(session, details, &m_handler);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    }
public:
    TwoFactorChangeLimitsHandler(const QJsonObject& details, Wallet* wallet)
        : Handler(wallet)
        , m_details(details)
    {
    }
};

class TwoFactorResetHandler : public Handler
{
    const QByteArray m_email;
    void init(GA_session* session) override {
        const uint32_t is_dispute = GA_FALSE;
        int res = GA_twofactor_reset(session, m_email.data(), is_dispute, &m_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    TwoFactorResetHandler(const QByteArray& email, Wallet* wallet)
        : Handler(wallet)
        , m_email(email)
    {
    }
};

class TwoFactorCancelResetHandler : public Handler
{
    void init(GA_session* session) override {
        int res = GA_twofactor_cancel_reset(session, &m_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    TwoFactorCancelResetHandler(Wallet* wallet)
        : Handler(wallet)
    {
    }
};

Controller::Controller(QObject* parent)
    : QObject(parent)
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
    QMetaObject::invokeMethod(context(), [this, handler] {
        QMetaObject::invokeMethod(this, [handler] {
            handler->exec();
        }, Qt::QueuedConnection);
    }, Qt::QueuedConnection);
}

QObject* Controller::context() const
{
    Wallet* w = wallet();
    return w ? w->m_context : nullptr;
}

GA_session* Controller::session() const
{
    Wallet* w = wallet();
    return w ? w->m_session : nullptr;
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
    // Avoid unnecessary calls to GA_change_settings
    bool updated = true;
    auto settings = wallet()->settings();
    for (auto i = data.begin(); i != data.end(); ++i) {
        if (settings.value(i.key()) != i.value()) {
            updated = false;
            break;
        }
    }
    if (updated) return;

    // Check if wallet is undergoing reset
    if (wallet()->isLocked()) return;

    auto handler = new ChangeSettingsHandler(data, wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        wallet()->updateSettings();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::sendRecoveryTransactions()
{
    auto handler = new SendNLocktimesHandler(wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        wallet()->updateSettings();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::enableTwoFactor(const QString& method, const QString& data)
{
    auto details = QJsonObject{
        { "data", data },
        { "enabled", true }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method.toLatin1(), details, wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        wallet()->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::disableTwoFactor(const QString& method)
{
    auto details = QJsonObject{
        { "enabled", false }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method.toLatin1(), details, wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        wallet()->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::changeTwoFactorLimit(bool is_fiat, const QString& limit)
{
    auto unit = wallet()->settings().value("unit").toString().toLower();
    auto details = QJsonObject{
        { "is_fiat", is_fiat },
        { is_fiat ? "fiat" : unit, limit }
    };
    auto handler = new TwoFactorChangeLimitsHandler(details, wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        wallet()->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::requestTwoFactorReset(const QString& email)
{
    auto handler = new TwoFactorResetHandler(email.toLatin1(), wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        wallet()->updateConfig();
        // TODO: updateConfig doesn't update 2f reset data,
        // it's only updated after authentication in GDK,
        // so force wallet lock for now.
        wallet()->setLocked(true);
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::cancelTwoFactorReset()
{
    auto handler = new TwoFactorCancelResetHandler(wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        wallet()->updateConfig();
        // TODO: updateConfig doesn't update 2f reset data,
        // it's only updated after authentication in GDK,
        // so force wallet unlock for now.
        wallet()->setLocked(false);
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::setRecoveryEmail(const QString& email)
{
    const auto method = QByteArray{"email"};
    const auto details = QJsonObject{
        { "data", email.toLatin1().data() },
        { "confirmed", true },
        { "enabled", false }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method, details, wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();
        wallet()->updateConfig();
    });
    connect(handler, &Handler::done, this, [this] {
        auto details = QJsonObject{
            { "notifications" , QJsonValue({
                { "email_incoming", true },
                { "email_outgoing", true }})
            }
        };
        auto handler = new ChangeSettingsHandler(details, wallet());
        connect(handler, &Handler::done, this, [this, handler] {
            handler->deleteLater();
            emit finished();
        });
        exec(handler);
    });
    exec(handler);
}
