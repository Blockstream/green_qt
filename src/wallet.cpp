#include "account.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "util.h"
#include "wallet.h"

#include <QDebug>
#include <QJsonObject>
#include <QSettings>
#include <QTimer>
#include <QNetworkConfigurationManager>

static void notification_handler(void* context, const GA_json* details)
{
    Wallet* wallet = static_cast<Wallet*>(context);
    auto notification = Json::toObject(details);
    QMetaObject::invokeMethod(wallet, [wallet, notification] {
        wallet->handleNotification(notification);
    });
}


Wallet::Wallet(QObject *parent)
    : QObject(parent)
{
    m_thread = new QThread(this);
    m_context = new QObject;

    m_context->moveToThread(m_thread);
    m_thread->start();
}

void Wallet::connect()
{
    Q_ASSERT(m_connection == Disconnected);
    setConnection(Connecting);
    connectNow();
}

void Wallet::connectNow()
{
    Q_ASSERT(m_network);

    if (m_connection == Disconnected) return;

    QMetaObject::invokeMethod(m_context, [this] {
        QJsonObject params{
            { "name", m_network->id() },
            { "log_level", "debug" },
            { "use_tor", m_use_tor }
        };

        if (!m_proxy.isEmpty()) {
            params.insert("proxy", m_proxy);
        }

        int res;

        if (!m_session) {
            res = GA_create_session(&m_session);
            Q_ASSERT(res == GA_OK);

            res = GA_set_notification_handler(m_session, notification_handler, this);
            Q_ASSERT(res == GA_OK);
//            res = GA::reconnect_hint(m_session, {{ "hint", "now" }});
//            Q_ASSERT(res == GA_OK);
        }

        res = GA::connect(m_session, params);
        qDebug() << "connect result" << res << params;

        if (res == GA_OK) {
            qDebug("NOW CONNECTED");
            setConnection(Connected);
            return;
        }

        if (res == GA_RECONNECT) {
            res = GA_disconnect(m_session);
            Q_ASSERT(res == GA_OK);

            QTimer::singleShot(1000, this, [this] { connectNow(); });
            return;
        }

        setConnection(Disconnected);

//        GA_destroy_session(m_session);
//        m_session = nullptr;

//        if (res == GA_RECONNECT) {

//            res = GA::reconnect_hint(m_session, {{ "hint", "now" }});
//            Q_ASSERT(res == GA_OK);

//            QTimer::singleShot(1000, this, [this] { connect(); });
//            return;
//        }

    });
}

void Wallet::disconnect()
{
    Q_ASSERT(m_connection != Disconnected);
    setConnection(Disconnected);
}

Wallet::~Wallet()
{
    if (m_session) {
        QMetaObject::invokeMethod(m_context, [this] {
            int res = GA_disconnect(m_session);
            Q_ASSERT(res == GA_OK);

            res = GA_destroy_session(m_session);
            Q_ASSERT(res == GA_OK);
        }, Qt::BlockingQueuedConnection);
    }
    if (m_thread) {
        m_context->deleteLater();
        m_thread->quit();
        m_thread->wait();
    }
}

void Wallet::setNetwork(Network* network)
{
    Q_ASSERT(!m_network);
    m_network = network;
    emit networkChanged(m_network);
}

void Wallet::setName(const QString& name)
{
    Q_ASSERT(m_name.isEmpty());
    m_name = name;
    emit nameChanged(m_name);
}

QJsonObject Wallet::settings() const
{
    return m_settings;
}

QJsonObject Wallet::currencies() const
{
    return m_currencies;
}

QQmlListProperty<Account> Wallet::accounts()
{
    return QQmlListProperty<Account>(this, m_accounts);
}

void Wallet::handleNotification(const QJsonObject &notification)
{
    QString event = notification.value("event").toString();
    Q_ASSERT(!event.isEmpty());
    Q_ASSERT(notification.contains(event));

    QJsonValue data = notification.value(event);

    m_events.insert(event, data);
    emit eventsChanged(m_events);

    if (event == "network") {
        QJsonObject network = data.toObject();
        if (!network.value("connected").toBool()) {
            setConnection(Connecting);
            return;
        }

        setConnection(Connected);
        if (network.value("login_required").toBool()) {
            setAuthentication(Unauthenticated);
        } else {
            setAuthentication(Authenticated);
        }
        return;
    }

    if (event == "transaction") {
        // This set contains all accounts that have to be updated due
        // to the received transaction event.
        QSet<Account*> accounts;

        QJsonObject transaction = data.toObject();
        for (auto pointer : transaction.value("subaccounts").toArray()) {
            auto account = m_accounts_by_pointer.value(pointer.toInt());
            account->handleNotification(notification);
            accounts.insert(account);
        }

        QMetaObject::invokeMethod(m_context, [this, accounts] {
            // First get balance for each account.
            for (auto account : accounts) {
                auto result = GA::process_auth([=] (GA_auth_handler** call) {
                    GA_json* details = Json::fromObject({
                        { "subaccount", account->m_pointer },
                        { "num_confs", 0 }
                    });

                    int err = GA_get_balance(m_session, details, call);
                    Q_ASSERT(err == GA_OK);
                    GA_destroy_json(details);
                });

                Q_ASSERT(result.value("status").toString() == "done");
                auto balance = result.value("result").toObject();

                // TODO: handle m_json concurrency
                account->m_json.insert("satoshi", balance);
            }
            // Now update all account balances at once.
            for (auto account : accounts) {
                emit account->jsonChanged();
                emit account->balanceChanged();
            }

            quint64 balance = 0;
            for (auto account : m_accounts) {
                balance += static_cast<quint64>(account->m_json.value("satoshi").toObject().value("btc").toInt());
            }
            setBalance(balance);
        });

        return;
    }

    if (event == "settings") {
        m_settings = data.toObject();
        emit settingsChanged();
        return;
    }

    if (event == "twofactor_reset") {
        Q_ASSERT(!data.toObject().value("is_active").toBool());
        return;
    }

    if (event == "fees") {
        // TODO: fees are being used in QML as `event.fees`.
        return;
    }

    if (event == "block") {
        for (auto account : m_accounts) {
            if (account->m_have_unconfirmed) {
                // reloading all transactions if at least one transaction is unconfirmed.
                account->reload();
            }
        }
        return;
    }

    qDebug() << "UNHANDLED NOTIFICATION" << notification;
}

QJsonObject Wallet::events() const
{
    return m_events;
}

QStringList Wallet::mnemonic() const
{
    QStringList result;
    QMetaObject::invokeMethod(m_context, [this, &result] {
        char* mnemonic = nullptr;
        int err = GA_get_mnemonic_passphrase(m_session, "", &mnemonic);
        Q_ASSERT(err == GA_OK);
        result = QString(mnemonic).split(' ');
        GA_destroy_string(mnemonic);
    }, Qt::BlockingQueuedConnection);
    return result;
}

qint64 Wallet::balance() const
{
    return m_balance;
}

void Wallet::changePin(const QByteArray& pin)
{
    char* mnemonic;
    int err = GA_get_mnemonic_passphrase(m_session, "", &mnemonic);
    Q_ASSERT(err == GA_OK);
    GA_json* pin_data;
    err = GA_set_pin(m_session, mnemonic, pin.constData(), "test", &pin_data);
    Q_ASSERT(err == GA_OK);
    GA_destroy_string(mnemonic);

    char* str;
    err = GA_convert_json_to_string(pin_data, &str);
    Q_ASSERT(err == GA_OK);
    m_pin_data = QByteArray(str);
    GA_destroy_json(pin_data);
    GA_destroy_string(str);

    QSettings settings(GetDataFile("app", "wallets.ini"), QSettings::IniFormat);
    const int count = settings.beginReadArray("wallets");
    settings.endArray();
    settings.beginWriteArray("wallets", count);
    settings.setArrayIndex(m_index);
    settings.setValue("pin_data", m_pin_data);
    settings.endArray();
}

void Wallet::login(const QByteArray& pin)
{
    Q_ASSERT(m_login_attempts_remaining > 0);

    if (m_pin_data.isEmpty()) return;

    setAuthentication(Authenticating);

    QMetaObject::invokeMethod(m_context, [this, pin] {
        GA_json* pin_data;
        int err = GA_convert_string_to_json(m_pin_data.constData(), &pin_data);
        err = GA_login_with_pin(m_session, pin.constData(), pin_data);
        qDebug() << "GA_login_with_pin" << err;
        GA_destroy_json(pin_data);

        const bool authenticated = err == GA_OK;

        int login_attempts_remaining = m_login_attempts_remaining;
        if (err == GA_NOT_AUTHORIZED) {
            login_attempts_remaining --;
        } else if (m_login_attempts_remaining < 3) {
            login_attempts_remaining = 3;
        }

        if (m_login_attempts_remaining != login_attempts_remaining) {
            m_login_attempts_remaining = login_attempts_remaining;

            QMetaObject::invokeMethod(this, [this] {
                QSettings settings;
                settings.beginWriteArray("wallets");
                settings.setArrayIndex(m_index);
                settings.setValue("login_attempts_remaining", m_login_attempts_remaining);
                settings.endArray();

                emit loginAttemptsRemainingChanged(m_login_attempts_remaining);
            }, Qt::QueuedConnection);
        }

        if (!authenticated) {
            qDebug("AUTH FAILED");
            setAuthentication(Unauthenticated);
            return;
        }

        GA_json* currencies;
        err = GA_get_available_currencies(m_session, &currencies);
        qDebug() << "GA_get_available_currencies result: " << err;
        Q_ASSERT(err == GA_OK);
        m_currencies = Json::toObject(currencies);
        GA_destroy_json(currencies);

        updateSettings();

        reload();

        setAuthentication(Authenticated);
    });
}



void Wallet::test()
{
    QMetaObject::invokeMethod(m_context, [this] {
        auto result = GA::process_auth([this] (GA_auth_handler** call) {
            GA_json* hw_device;
            GA_convert_string_to_json(
                "{"
                "   \"device\": {"
                "      \"name\": \"Ledger\","
                "      \"supports_arbitrary_scripts\": true,"
                "      \"supports_low_r\": false"
                "   }"
                "}",
                &hw_device);

            int err = GA_register_user(m_session, hw_device, "", call);
            Q_ASSERT(err == GA_OK);

            GA_destroy_json(hw_device);
        });
        Q_ASSERT(result.value("status").toString() == "done");
    });
}

void Wallet::signup(const QStringList& mnemonic, const QString& password, const QByteArray& pin)
{
    setAuthentication(Authenticating);

    QMetaObject::invokeMethod(m_context, [this, pin, mnemonic, password] {
        QByteArray raw_mnemonic = mnemonic.join(' ').toLatin1();

        GA_json* hw_device;
        GA_convert_string_to_json("{}", &hw_device);

        auto result = GA::process_auth([&] (GA_auth_handler** call) {
            int err = GA_register_user(m_session, hw_device, raw_mnemonic.constData(), call);
            Q_ASSERT(err == GA_OK);
        });
        Q_ASSERT(result.value("status").toString() == "done");

        result = GA::process_auth([&] (GA_auth_handler** call) {
            int err = GA_login(m_session, hw_device, raw_mnemonic.constData(), "", call);
            Q_ASSERT(err == GA_OK);
        });
        Q_ASSERT(result.value("status").toString() == "done");

        GA_destroy_json(hw_device);

        GA_json* pin_data;
        int err = GA_set_pin(m_session, raw_mnemonic.constData(), pin.constData(), "test", &pin_data);
        char* str;
        GA_convert_json_to_string(pin_data, &str);
        m_pin_data = QByteArray(str);
        GA_destroy_json(pin_data);
        GA_destroy_string(str);

        QMetaObject::invokeMethod(this, [this]{
            QSettings settings(GetDataFile("app", "wallets.ini"), QSettings::IniFormat);
            m_index = settings.beginReadArray("wallets");
            settings.endArray();
            settings.beginWriteArray("wallets");
            settings.setArrayIndex(m_index);
            settings.setValue("proxy", m_proxy);
            settings.setValue("use_tor", m_use_tor);
            settings.setValue("network", m_network->id());
            settings.setValue("pin_data", m_pin_data);
            settings.setValue("name", m_name);
            settings.setValue("login_attempts_remaining", m_login_attempts_remaining);
            settings.endArray();
        }, Qt::BlockingQueuedConnection);

        reload();
        updateConfig();

        setAuthentication(Authenticated);
    });
}


void Wallet::recover(const QString& name, const QStringList& mnemonic, const QByteArray& pin)
{
    qDebug() << name << mnemonic << pin;
    QMetaObject::invokeMethod(m_context, [this, name, pin, mnemonic] {
        QByteArray raw_mnemonic = mnemonic.join(' ').toLatin1();

        GA::process_auth([&] (GA_auth_handler** call) {
            GA_json* hw_device;
            GA_convert_string_to_json("{}", &hw_device);

            int err = GA_login(m_session, hw_device, raw_mnemonic.constData(), "", call);
            Q_ASSERT(err == GA_OK);

            GA_destroy_json(hw_device);
        });

        GA_json* pin_data;
        GA_set_pin(m_session, raw_mnemonic.constData(), pin.constData(), "test", &pin_data);

        qDebug() << "PIN SET! " << mnemonic << pin;

        if (true) {
            char* str;
            GA_convert_json_to_string(pin_data, &str);
            QSettings settings;
            int index = settings.beginReadArray("wallets");
            settings.endArray();
            settings.beginWriteArray("wallets");
            settings.setArrayIndex(index);
            settings.setValue("pin_data", QByteArray(str));
            settings.setValue("name", name);
            settings.endArray();
            GA_destroy_string(str);
        }

        GA_destroy_json(pin_data);
    });
}

void Wallet::reload()
{
    QMetaObject::invokeMethod(m_context, [this] {
        QJsonArray accounts = GA::get_subaccounts(m_session);

        QMetaObject::invokeMethod(this, [this, accounts] {
            quint64 balance  = 0;

            QMap<int, Account*> accounts_by_pointer = m_accounts_by_pointer;

            for (QJsonValue data : accounts) {
                QJsonObject json = data.toObject();
                int pointer = json.value("pointer").toInt();
                Account* account = accounts_by_pointer.take(pointer);
                if (!account) {
                    account = new Account(this);
                    m_accounts.append(account);
                    m_accounts_by_pointer.insert(pointer, account);
                }
                account->update(data.toObject());
                account->reload();

                balance += static_cast<quint64>(json.value("satoshi").toObject().value("btc").toInt());
            }

            Q_ASSERT(accounts_by_pointer.isEmpty());

            emit accountsChanged();

            setBalance(balance);
        });
    });
}

void Wallet::updateConfig()
{
    GA_json* config;
    GA_get_twofactor_config(m_session, &config);
    m_config = Json::toObject(config);
    GA_destroy_json(config);
    emit configChanged();
}

void Wallet::updateSettings()
{
    GA_json* settings;
    int err = GA_get_settings(m_session, &settings);
    Q_ASSERT(err == GA_OK);
    m_settings = Json::toObject(settings);
    GA_destroy_json(settings);
    emit settingsChanged();
}

void Wallet::setup2F()
{

}

void Wallet::setConnection(ConnectionStatus connection)
{
    if (m_connection == connection) return;
    qDebug() << "connection change" << m_connection << " -> " << connection;
    m_connection = connection;
    emit connectionChanged();
}

void Wallet::setAuthentication(AuthenticationStatus authentication)
{
    if (m_authentication == authentication) return;
    qDebug() << "authentication change" << m_authentication << " -> " << authentication;
    m_authentication = authentication;
    emit authenticationChanged();
}

void Wallet::setBalance(const quint64 balance)
{
    if (m_balance == balance) return;
    m_balance = balance;
    emit balanceChanged();
}

QJsonObject Wallet::convert(qint64 sats)
{
    auto details = Json::fromObject({{ "satoshi", sats }});
    GA_json* balance;
    int err = GA_convert_amount(m_session, details, &balance);
    Q_ASSERT(err == GA_OK);
    GA_destroy_json(details);
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);

    return result;
}
