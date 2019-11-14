#include "account.h"
#include "ga.h"
#include "json.h"
#include "util.h"
#include "wallet.h"

#include <QDebug>
#include <QJsonObject>
#include <QSettings>
#include <QTimer>

static void notification_handler(void* context, const GA_json* details)
{
    Wallet* wallet = static_cast<Wallet*>(context);
    wallet->handleNotification(Json::toObject(details));
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
    Q_ASSERT(!(m_status & Connected));

    setStatus(Connecting);

    connectNow();
}


void Wallet::connectNow()
{
    if (m_status == Disconnected) return;

    QMetaObject::invokeMethod(m_context, [this] {
        QJsonObject params{
            { "name", m_network },
            { "log_level", "info" },
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
        qDebug() << "connect result" << res;

        if (res == GA_OK) {
            qDebug("NOW CONNECTED");
            setStatus(Connected);
            return;
        }

        if (res == GA_RECONNECT) {
            res = GA_disconnect(m_session);
            Q_ASSERT(res == GA_OK);

            QTimer::singleShot(1000, this, [this] { connectNow(); });
            return;
        }

        setStatus(Disconnected);

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
    Q_ASSERT(m_status != Disconnected);
    setStatus(Disconnected);
}

Wallet::~Wallet()
{
    if (m_session) {
        QMetaObject::invokeMethod(m_context, [this] {
            int res = GA_disconnect(m_session);
            Q_ASSERT(res == GA_OK);

            res = GA_destroy_session(m_session);
            Q_ASSERT(res == GA_OK);
            emit isOnlineChanged();
        }, Qt::BlockingQueuedConnection);
    }
    if (m_thread) {
        m_context->deleteLater();
        m_thread->quit();
        m_thread->wait();
    }
}

QJsonObject Wallet::settings() const
{
    return m_settings;
}

QJsonObject Wallet::currencies() const
{
    return m_currencies;
}

QList<QObject*> Wallet::accounts() const
{
    return m_accounts;
}

void Wallet::handleNotification(const QJsonObject &notification)
{
    qDebug() << "GOT NOTIFICATION" << notification;

    QString event = notification.value("event").toString();
    Q_ASSERT(!event.isEmpty());
    Q_ASSERT(notification.contains(event));

    QJsonObject data = notification.value(event).toObject();

    m_events.insert(event, data);
    emit eventsChanged(m_events);

    if (event == "network") {
        if (!data.value("connected").toBool()) {
            setStatus(Connecting);
        } else if (data.value("login_required").toBool()) {
            setStatus(Connected);
        } else {
            setStatus(Authenticated);
        }
        return;
    }

    if (event == "transaction") {
        for (auto pointer : data.value("subaccounts").toArray()) {
            m_accounts_by_pointer.value(pointer.toInt())->handleNotification(notification);
        }

    }
}

QJsonObject Wallet::events() const
{
    return m_events;
}

QStringList Wallet::mnemonic() const
{
    return m_mnemonic;
}

void Wallet::login(const QByteArray& pin)
{
    Q_ASSERT(m_login_attempts_remaining > 0);

    if (m_pin_data.isEmpty()) return;

    setStatus(Authenticating);

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
            setStatus(Connected);
            return;
        }

        char* mnemonic = nullptr;
        err = GA_get_mnemonic_passphrase(m_session, "", &mnemonic);
        qDebug() << "MNEMONIC: " << err << mnemonic;
        m_mnemonic = QString(mnemonic).split(' ');
        GA_destroy_string(mnemonic);

        GA_json* config;
        GA_get_twofactor_config(m_session, &config);
        qDebug() << "CONFIG;" <<  Json::toObject(config);
        GA_destroy_json(config);

        GA_json* settings;
        err = GA_get_settings(m_session, &settings);
        Q_ASSERT(err == GA_OK);
        m_settings = Json::toObject(settings);
        GA_destroy_json(settings);

        GA_json* currencies;
        err = GA_get_available_currencies(m_session, &currencies);
        Q_ASSERT(err == GA_OK);
        m_currencies = Json::toObject(currencies);
        GA_destroy_json(currencies);

        reload();

        setStatus(Authenticated);
    });
}



void Wallet::test()
{
    QMetaObject::invokeMethod(m_context, [this] {
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

        GA_auth_handler* call;
        int err = GA_register_user(m_session, hw_device, "", &call);
        Q_ASSERT(err == GA_OK);
        GA::process_auth(call);
        GA_destroy_auth_handler(call);
    });
}

void Wallet::signup(const QStringList& mnemonic, const QString& password, const QByteArray& pin)
{
    setStatus(Authenticating);

    QMetaObject::invokeMethod(m_context, [this, pin, mnemonic, password] {
        QByteArray raw_mnemonic = mnemonic.join(' ').toLatin1();

        GA_json* hw_device;
        GA_convert_string_to_json("{}", &hw_device);

        GA_auth_handler* call;
        int err = GA_register_user(m_session, hw_device, raw_mnemonic.constData(), &call);
        Q_ASSERT(err == GA_OK);
        GA::process_auth(call);
        GA_destroy_auth_handler(call);

        err = GA_login(m_session, hw_device, raw_mnemonic.constData(), password.toLatin1().constData(), &call);
        Q_ASSERT(err == GA_OK);

        GA::process_auth(call);
        GA_destroy_auth_handler(call);

        GA_destroy_json(hw_device);

        GA_json* pin_data;
        err = GA_set_pin(m_session, raw_mnemonic.constData(), pin.constData(), "test", &pin_data);
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
            settings.setValue("network", m_network);
            settings.setValue("pin_data", m_pin_data);
            settings.setValue("name", m_name);
            settings.setValue("login_attempts_remaining", m_login_attempts_remaining);
            settings.endArray();
        }, Qt::BlockingQueuedConnection);

        reload();

        setStatus(Authenticated);
    });
}


void Wallet::recover(const QString& name, const QStringList& mnemonic, const QByteArray& pin)
{
    qDebug() << name << mnemonic << pin;
    QMetaObject::invokeMethod(m_context, [this, name, pin, mnemonic] {
        QByteArray raw_mnemonic = mnemonic.join(' ').toLatin1();

        GA_json* hw_device;
        GA_convert_string_to_json("{}", &hw_device);

        GA_auth_handler* call;

        qDebug() << name << mnemonic << pin;
        int err = GA_login(m_session, hw_device, raw_mnemonic.constData(), "", &call);
        Q_ASSERT(err == GA_OK);

        GA::process_auth(call);
        GA_destroy_auth_handler(call);

        qDebug() << name << mnemonic << pin;
        GA_destroy_json(hw_device);

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

// Used to sum two balances
/*static QJsonObject AddBalances(const QJsonObject& a, const QJsonObject& b)
{
    QJsonObject r;
    QStringList keys = a.keys() + b.keys();
    keys.removeDuplicates();

    for (const QString& key : keys) {
        if (key.startsWith("fiat_")) continue;

        QJsonValue va = a.value(key);
        QJsonValue vb = b.value(key);

        if (va.isObject() || vb.isObject()) {
            r.insert(key, AddBalances(va.toObject(), vb.toObject()));
        } else if (va.isString() || vb.isString()) {
            r.insert(key, QString::number(va.toString().toDouble() + vb.toString().toDouble()));
        } else if (va.isDouble() || vb.isDouble()) {
            r.insert(key, va.toDouble() + vb.toDouble());
        }
    }

    return r;
}*/


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

void Wallet::setup2F()
{

}

void Wallet::setStatus(Status status)
{
    if (m_status == status) return;
    qDebug() << "status change" << m_status << " -> " << status;
    m_status = status;
    emit statusChanged();
}

void Wallet::setBalance(const quint64 balance)
{
    if (m_balance == balance) return;
    m_balance = balance;
    emit balanceChanged(m_balance);
}

AmountConverter::AmountConverter(QObject *parent) : QObject(parent)
{

}

Wallet *AmountConverter::wallet() const
{
    return m_wallet;
}

QJsonObject AmountConverter::input() const
{
    return m_input;
}

QJsonObject AmountConverter::output() const
{
    return m_output;
}

void AmountConverter::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet)
        return;

    m_wallet = wallet;
    emit walletChanged(m_wallet);
    update();
}

void AmountConverter::setInput(const QJsonObject &input)
{
    if (m_input == input)
        return;

    m_input = input;
    emit inputChanged(m_input);
    update();
}

bool AmountConverter::valid() const
{
    return m_valid;
}

void AmountConverter::update()
{
    if (!m_wallet || m_input.isEmpty()) {
        if (m_valid) {
            m_valid = false;
            emit validChanged(m_valid);
        }
    }

    if (!m_wallet) return;

    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        m_output = GA::convert_amount(m_wallet->m_session, m_input);
        emit outputChanged(m_output);
        if (m_valid == m_output.isEmpty()) {
            m_valid = !m_output.isEmpty();
            emit validChanged(m_valid);
        }
    });
}
