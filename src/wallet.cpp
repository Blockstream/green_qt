#include "account.h"
#include "ga.h"
#include "json.h"
#include "wallet.h"

#include <QDebug>
#include <QSettings>

#include <QJsonObject>

static void notification_handler(void* context, const GA_json* details)
{
    Wallet* wallet = static_cast<Wallet*>(context);
    wallet->handleNotification(Json::toObject(details));
}


Wallet::Wallet(QObject *parent) : QObject(parent)
{
    GA_json* config;
    GA_convert_string_to_json("{}", &config);
    GA_init(config);
    GA_destroy_json(config);

    m_context->moveToThread(m_thread);
    m_thread->start();

    QMetaObject::invokeMethod(m_context, [this] {
        int res = GA_create_session(&m_session);
        Q_ASSERT(res == GA_OK);

        GA_set_notification_handler(m_session, notification_handler, this);

        res = GA::connect(m_session, {
           { "name", "testnet" },
           { "log_level", "info" },
        });

        m_online = res == GA_OK;
        emit isOnlineChanged();
    });
}

Wallet::~Wallet()
{
    QMetaObject::invokeMethod(m_context, [this] {
        int res = GA_disconnect(m_session);
        Q_ASSERT(res == GA_OK);

        res = GA_destroy_session(m_session);
        Q_ASSERT(res == GA_OK);
        emit isOnlineChanged();
    });
}

QList<QObject*> Wallet::accounts() const
{
    return m_accounts;
}

bool Wallet::isAuthenticating() const
{
    return m_authenticating;
}

void Wallet::handleNotification(const QJsonObject &notification)
{
    qDebug() << "GOT NOTIFICATION" << notification;

    QString event = notification.value("event").toString();
    if (!event.isEmpty() && notification.contains(event)) {
        m_events.insert(event, notification.value(event));
        emit eventsChanged(m_events);
    }

    if (notification.value("event").toString() == "transaction") {
        for (auto pointer : notification.value("transaction").toObject().value("subaccounts").toArray()) {
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
    if (m_pin_data.isEmpty()) return;

    m_authenticating = true;
    emit isAuthenticatingChanged(m_authenticating);

    QMetaObject::invokeMethod(m_context, [this, pin] {
        GA_json* pin_data;
        int err = GA_convert_string_to_json(m_pin_data.constData(), &pin_data);
        qDebug() << "CONVERT STRING TO JSON:" << err << m_pin_data << pin;
        err = GA_login_with_pin(m_session, pin.constData(), pin_data);
        GA_destroy_json(pin_data);
        m_logged = err == GA_OK;
        qDebug("ADASD");
        qDebug() << err;
        emit isLoggedChanged();

        char* mnemonic = nullptr;
        err = GA_get_mnemonic_passphrase(m_session, "", &mnemonic);
        qDebug() << "MNEMONIC: " << err << mnemonic;
        m_mnemonic = QString(mnemonic).split(' ');
        GA_destroy_string(mnemonic);

        QMetaObject::invokeMethod(this, [this] {
            m_authenticating = false;
            emit isAuthenticatingChanged(m_authenticating);
        });

        GA_json* config;
        GA_get_twofactor_config(m_session, &config);
        qDebug() << "CONFIG;" <<  Json::toObject(config);
        GA_destroy_json(config);

        GA_json* settings;
        err = GA_get_settings(m_session, &settings);
        qDebug() << "SETTINGS:" <<  Json::toObject(settings);
        GA_destroy_json(settings);

        GA_json* currencies;
        GA_get_available_currencies(m_session, &currencies);
        qDebug() << "CURRENCIES:" << Json::toObject(currencies);
        GA_destroy_json(currencies);
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
        qDebug() << "AFTER REGISTER user" << err;
        Q_ASSERT(err == GA_OK);
        GA::process_auth(call);
        GA_destroy_auth_handler(call);
    });
}

void Wallet::signup(const QString& name, const QStringList& mnemonic, const QByteArray& pin)
{
    QMetaObject::invokeMethod(m_context, [this, name, pin, mnemonic] {
        QByteArray raw_mnemonic = mnemonic.join(' ').toLatin1();

        GA_json* hw_device;
        GA_convert_string_to_json("{}", &hw_device);

        GA_auth_handler* call;
        int err = GA_register_user(m_session, hw_device, raw_mnemonic.constData(), &call);
        qDebug() << "AFTER REGISTER user" << err;
        Q_ASSERT(err == GA_OK);
        GA::process_auth(call);
        GA_destroy_auth_handler(call);

            qDebug() << mnemonic << pin;

        err = GA_login(m_session, hw_device, raw_mnemonic.constData(), "", &call);
        Q_ASSERT(err == GA_OK);

        m_logged = true;
        emit isLoggedChanged();

        GA::process_auth(call);
        GA_destroy_auth_handler(call);

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

        m_logged = true;
        emit isLoggedChanged();

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

void Wallet::reload()
{
    Q_ASSERT(m_online);

    QMetaObject::invokeMethod(m_context, [this] {
        QJsonArray accounts = GA::get_subaccounts(m_session);

        QMetaObject::invokeMethod(this, [this, accounts] {
            QMap<int, Account*> accounts_by_pointer = m_accounts_by_pointer;

            bool changed = false;
            for (QJsonValue data : accounts) {
                QJsonObject json = data.toObject();
                int pointer = json.value("pointer").toInt();
                Account* account = accounts_by_pointer.take(pointer);
                if (!account) {
                    account = new Account(this);
                    m_accounts.append(account);
                    m_accounts_by_pointer.insert(pointer, account);
                    changed = true;
                }
                account->update(data.toObject());
                account->reload();
            }

            Q_ASSERT(accounts_by_pointer.isEmpty());

            //if (changed)
            emit accountsChanged();
        });
    });
}

QStringList Wallet::generateMnemonic() const
{
    char* mnemonic;
    GA_generate_mnemonic(&mnemonic);
    auto result = QString(mnemonic).split(' ');
    GA_destroy_string(mnemonic);
    return result;
}

void Wallet::setup2F()
{

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
