#include "controller.h"
#include "device.h"
#include "handler.h"
#include "json.h"
#include "wallet.h"

#include <QQmlContext>
#include <QQmlEngine>

#include <gdk.h>

class ChangeSettingsHandler : public Handler
{
    QJsonObject m_data;
public:
    ChangeSettingsHandler(const QJsonObject& data, QObject* parent)
        : Handler(parent)
        , m_data(data) { }
    void init(GA_session* session) override {
        auto data = Json::fromObject(m_data);
        int err = GA_change_settings(session, data, &m_handler);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(data);
        Q_ASSERT(err == GA_OK);
    }
};


class SendNLocktimesHandler : public Handler
{
public:
    SendNLocktimesHandler(QObject* parent)
        : Handler(parent) { }
    void init(GA_session* session) override {
        int err = GA_send_nlocktimes(session);
        // Can't Q_ASSERT(err == GA_OK) because err != GA_OK
        // if no utxos found (e.g. new wallet)
        Q_UNUSED(err);
    }
};

class ChangeSettingsTwoFactorHandler : public Handler
{
    QByteArray m_method;
    QJsonObject m_details;
public:
    ChangeSettingsTwoFactorHandler(const QByteArray& method, const QJsonObject& details, QObject* parent)
        : Handler(parent)
        , m_method(method)
        , m_details(details) { }
    void init(GA_session* session) override {
        auto details = Json::fromObject(m_details);
        int res = GA_change_settings_twofactor(session, m_method.data(), details, &m_handler);
        Q_ASSERT(res == GA_OK);
        res = GA_destroy_json(details);
        Q_ASSERT(res == GA_OK);
    }
};

class TwoFactorChangeLimitsHandler : public Handler
{
    QJsonObject m_details;
public:
    TwoFactorChangeLimitsHandler(const QJsonObject& details, QObject* parent)
        : Handler(parent)
        , m_details(details) { }
    void init(GA_session* session) override {
        auto details = Json::fromObject(m_details);
        int err = GA_twofactor_change_limits(session, details, &m_handler);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    }
};

class TwoFactorResetHandler : public Handler
{
    const QByteArray m_email;
public:
    TwoFactorResetHandler(const QByteArray& email, QObject* parent)
        : Handler(parent)
        , m_email(email) { }
    void init(GA_session* session) override {
        const uint32_t is_dispute = GA_FALSE;
        int res = GA_twofactor_reset(session, m_email.data(), is_dispute, &m_handler);
        Q_ASSERT(res == GA_OK);
    }
};

class TwoFactorCancelResetHandler : public Handler
{
public:
    TwoFactorCancelResetHandler(QObject* parent)
        : Handler(parent) {}
    void init(GA_session* session) override {
        int res = GA_twofactor_cancel_reset(session, &m_handler);
        Q_ASSERT(res == GA_OK);
    }
};

Controller::Controller(QObject* parent)
    : QObject(parent)
{
}

void Controller::exec(Handler* handler)
{
    // TODO get xpubs should be delegated
    connect(handler, &Handler::done, [this, handler] { emit done(handler); });
    connect(handler, &Handler::error, [this, handler] { emit error(handler); });
    connect(handler, &Handler::requestCode, [this, handler] { emit requestCode(handler); });
    connect(handler, &Handler::resolveCode, [this, handler] { emit resolveCode(handler); });
    connect(handler, &Handler::invalidCode, [this, handler] { emit invalidCode(handler); });
    QMetaObject::invokeMethod(context(), [this, handler] {
        handler->init(session());
        QMetaObject::invokeMethod(this, [handler] {
            handler->exec();
        }, Qt::QueuedConnection);
    }, Qt::QueuedConnection);


    connect(handler, &Handler::resolveCode, [this, handler] {
        const auto action = handler->result().value("action").toString();
        if (action == "get_xpubs") {
            for (auto path : handler->m_paths) {
                auto cmd = new GetWalletPublicKeyCommand(wallet()->network(), path);
                connect(cmd, &Command::finished, [cmd, handler] {
                    handler->m_xpubs.append(cmd->m_xpub);
                    if (handler->m_xpubs.size() == handler->m_paths.size()) {
                        handler->resolve({{ "xpubs", handler->m_xpubs }});
                    }
                });
                wallet()->m_device->exchange(cmd);
            }
            return;
        }

        if (action == "sign_tx") {
            Q_ASSERT(wallet()->m_device);

            auto required_data = handler->result().value("required_data").toObject();
            auto command = wallet()->m_device->signTransaction(required_data);
            connect(command, &Command::finished, [command, handler] {
                QJsonArray signatures;
                for (const auto& signature : command->signatures) {
                    qDebug() << signature.toHex();
                    signatures.append(QString::fromLocal8Bit(signature.toHex()));
                }
                handler->resolve({{ "signatures", signatures }});
            });
        }
    });
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

Wallet *Controller::wallet() const
{
    if (m_wallet) return m_wallet;
    auto context = qmlContext(this);
    if (!context) return nullptr;
    return qobject_cast<Wallet*>(context->contextProperty("wallet").value<QObject*>());
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

    auto handler = new ChangeSettingsHandler(data, this);
    connect(handler, &Handler::done, [this, handler] {
        wallet()->updateSettings();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::sendRecoveryTransactions()
{
    auto handler = new SendNLocktimesHandler(this);
    connect(handler, &Handler::done, [this, handler] {
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
    auto handler = new ChangeSettingsTwoFactorHandler(method.toLatin1(), details, this);
    connect(handler, &Handler::done, [this, handler] {
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
    auto handler = new ChangeSettingsTwoFactorHandler(method.toLatin1(), details, this);
    connect(handler, &Handler::done, [this, handler] {
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
    auto handler = new TwoFactorChangeLimitsHandler(details, this);
    connect(handler, &Handler::done, [this, handler] {
        // Two factor configuration has changed, update it.
        wallet()->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::requestTwoFactorReset(const QString& email)
{
    auto handler = new TwoFactorResetHandler(email.toLatin1(), this);
    connect(handler, &Handler::done, [this, handler] {
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
    auto handler = new TwoFactorCancelResetHandler(this);
    connect(handler, &Handler::done, [this, handler] {
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
    auto handler = new ChangeSettingsTwoFactorHandler(method, details, this);
    connect(handler, &Handler::done, [this, handler] {
        handler->deleteLater();
        wallet()->updateConfig();
    });
    connect(handler, &Handler::done, [this] {
        auto details = QJsonObject{
            { "notifications" , QJsonValue({
                { "email_incoming", true },
                { "email_outgoing", true }})
            }
        };
        auto handler = new ChangeSettingsHandler(details, this);
        connect(handler, &Handler::done, [this, handler] {
            handler->deleteLater();
            emit finished();
        });
        exec(handler);
    });
    exec(handler);
}
