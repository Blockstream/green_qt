#include "account.h"
#include "asset.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "util.h"
#include "wallet.h"

#include <QDebug>
#include <QJsonObject>
#include <QLocale>
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
    // TODO: instantiate only if needed
    m_thread = new QThread(this);
    m_context = new QObject;

    m_context->moveToThread(m_thread);
    m_thread->start();
}

void Wallet::connect(const QString& proxy, bool use_tor)
{
    if (m_connection == Connected) {
        Q_ASSERT(m_proxy == proxy && m_use_tor == use_tor);
    } else {
        setConnection(Connecting);
    }

    if (m_proxy != proxy) {
        m_proxy = proxy;
        emit proxyChanged(m_proxy);
    }
    if (m_use_tor != use_tor) {
        m_use_tor = use_tor;
        emit useTorChanged(m_use_tor);
    }

    connectNow();
}

void Wallet::connectNow()
{
    Q_ASSERT(m_network);

    if (m_connection == Disconnected) return;

    QMetaObject::invokeMethod(m_context, [this] {
        QJsonObject params{
            { "name", m_network->id() },
#ifdef QT_DEBUG
            { "log_level", "debug" },
#else
            { "log_level", "info" },
#endif
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

            m_session = nullptr;
            QTimer::singleShot(1000, this, [this] {
                connectNow();
            });
            return;
        }

        setConnection(Disconnected);
    });
}

void Wallet::disconnect()
{
    Q_ASSERT(m_connection != Disconnected);
    Q_ASSERT(m_authentication == Authenticated);

    if (m_logout_timer != -1 ) {
        killTimer(m_logout_timer);
        m_logout_timer = -1;
        qApp->removeEventFilter(this);
    }

    auto accounts = m_accounts;
    m_accounts.clear();
    m_accounts_by_pointer.clear();
    emit accountsChanged();

    m_settings = {};
    m_config = {};
    m_currencies = {};
    m_events = {};
    m_balance = 0;

    setConnection(Disconnected);
    setAuthentication(Unauthenticated);

    QMetaObject::invokeMethod(m_context, [this] {
        int err = GA_destroy_session(m_session);
        Q_ASSERT(err == GA_OK);
        m_session = nullptr;
    }, Qt::BlockingQueuedConnection);

    qDeleteAll(accounts);
    qDeleteAll(m_assets.values());
    m_assets.clear();
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

            QMetaObject::invokeMethod(this, [=] {
                // Now update all account balances at once.
                for (auto account : accounts) {
                    emit account->jsonChanged();
                    account->updateBalance();
                }

                quint64 balance = 0;
                for (auto account : m_accounts) {
                    balance += static_cast<quint64>(account->m_json.value("satoshi").toObject().value("btc").toInt());
                }
                setBalance(balance);
            }, Qt::QueuedConnection);
        });

        return;
    }

    if (event == "settings") {
        setSettings(data.toObject());
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

void Wallet::loginWithPin(const QByteArray& pin)
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
        } else if (login_attempts_remaining < 3) {
            login_attempts_remaining = 3;
        }

        if (m_login_attempts_remaining != login_attempts_remaining) {
            m_login_attempts_remaining = login_attempts_remaining;

            QMetaObject::invokeMethod(this, [this] {
                QSettings settings(GetDataFile("app", "wallets.ini"), QSettings::IniFormat);
                const int count = settings.beginReadArray("wallets");
                settings.endArray();
                settings.beginWriteArray("wallets", count);
                settings.setArrayIndex(m_index);
                settings.setValue("login_attempts_remaining", m_login_attempts_remaining);
                settings.endArray();

                emit loginAttemptsRemainingChanged(m_login_attempts_remaining);
            }, Qt::BlockingQueuedConnection);
        }

        if (!authenticated) {
            qDebug("AUTH FAILED");
            setAuthentication(Unauthenticated);
            return;
        }

        updateCurrencies();
        updateSettings();

        reload();
        updateConfig();

        setAuthentication(Authenticated);
    });
}

void Wallet::signup(const QStringList& mnemonic, const QByteArray& pin)
{
    Q_ASSERT(mnemonic.size() == 24);

    setAuthentication(Authenticating);

    QMetaObject::invokeMethod(m_context, [this, pin, mnemonic] {
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
        Q_ASSERT(err == GA_OK);
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

        updateCurrencies();
        reload();
        updateConfig();

        setAuthentication(Authenticated);
    });
}

void Wallet::login(const QStringList& mnemonic, const QString& password)
{
    Q_ASSERT(mnemonic.size() == 24 || mnemonic.size() == 27 && !password.isEmpty());

    setAuthentication(Authenticating);

    QMetaObject::invokeMethod(m_context, [this, mnemonic, password] {
        QByteArray raw_mnemonic = mnemonic.join(' ').toLatin1();

        GA_json* hw_device;
        GA_convert_string_to_json("{}", &hw_device);

        auto result = GA::process_auth([&] (GA_auth_handler** call) {
            int err = GA_login(m_session, hw_device, raw_mnemonic.constData(), password.toLatin1().constData(), call);
            Q_ASSERT(err == GA_OK);
        });

        GA_destroy_json(hw_device);

        if (result.value("status") != "done") return setAuthentication(Unauthenticated);

        updateCurrencies();
        reload();
        updateConfig();

        setAuthentication(Authenticated);
    });
}

void Wallet::setPin(const QStringList& mnemonic, const QByteArray& pin)
{
    Q_ASSERT(m_authentication == Authenticated);
    Q_ASSERT(m_name.isEmpty());
    Q_ASSERT(m_pin_data.isEmpty());

    QMetaObject::invokeMethod(m_context, [this, mnemonic, pin] {
        QByteArray raw_mnemonic = mnemonic.join(' ').toLatin1();

        GA_json* pin_data;
        int err = GA_set_pin(m_session, raw_mnemonic.constData(), pin.constData(), "test", &pin_data);
        Q_ASSERT(err == GA_OK);
        m_pin_data = Json::toByteArray(pin_data);
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

        if (m_network->isLiquid()) {
            refreshAssets();
        }
    });
}

void Wallet::refreshAssets()
{
    Q_ASSERT(m_network->isLiquid());

    QMetaObject::invokeMethod(m_context, [this] {
        auto params = Json::fromObject({
            { "assets", true },
            { "icons", true },
            { "refresh", true }
        });
        GA_json* output;
        int err = GA_refresh_assets(m_session, params, &output);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(params);
        Q_ASSERT(err == GA_OK);

        auto assets = Json::toObject(output);
        err = GA_destroy_json(output);
        Q_ASSERT(err == GA_OK);

        QMetaObject::invokeMethod(this, [this, assets] {
            auto icons = assets.value("icons").toObject();

            for (auto&& ref : assets.value("assets").toObject()) {
                QString id = ref.toObject().value("asset_id").toString();
                Asset* asset = getOrCreateAsset(id);
                asset->setData(ref.toObject());
                if (icons.contains(id)) {
                    asset->setIcon("data:image/png;base64," + icons.value(id).toString());
                }
            }
        });
    });
}

void Wallet::updateConfig()
{
    GA_json* config;
    int err = GA_get_twofactor_config(m_session, &config);
    Q_ASSERT(err == GA_OK);
    m_config = Json::toObject(config);
    GA_destroy_json(config);
    emit configChanged();

    setLocked(m_config.value("twofactor_reset").toObject().value("is_active").toBool());
}

void Wallet::updateSettings()
{
    GA_json* settings;
    int err = GA_get_settings(m_session, &settings);
    Q_ASSERT(err == GA_OK);
    auto data = Json::toObject(settings);
    GA_destroy_json(settings);
    setSettings(data);
}

void Wallet::updateCurrencies()
{
    GA_json* currencies;
    int err = GA_get_available_currencies(m_session, &currencies);
    Q_ASSERT(err == GA_OK);
    m_currencies = Json::toObject(currencies);
    GA_destroy_json(currencies);
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

QJsonObject Wallet::convert(qint64 sats) const
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

QString Wallet::formatAmount(qint64 amount, bool include_ticker) const
{
    return formatAmount(amount, include_ticker, m_settings.value("unit").toString());
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker, const QString& unit) const
{
    Q_ASSERT(m_network);
    auto str = convert(amount).value(unit == "\u00B5BTC" ? "ubtc" : unit.toLower()).toString();
    str = QLocale::system().toString(str.toDouble());
    if (include_ticker) {
        str += (m_network->isLiquid() ? " L-" : " ") + unit;
    }
    return str;
}

qint64 Wallet::amountToSats(const QString& amount) const
{
    return parseAmount(amount, m_settings.value("unit").toString());
}

qint64 Wallet::parseAmount(const QString& amount, const QString& unit) const
{
    if (amount.isEmpty()) return 0;
    QString sanitized_amount = amount;
    sanitized_amount.replace(',', '.');
    auto details = Json::fromObject({{ unit == "\u00B5BTC" ? "ubtc" : unit.toLower(), sanitized_amount }});
    GA_json* balance;
    int err = GA_convert_amount(m_session, details, &balance);
    if (err != GA_OK) return 0;
    GA_destroy_json(details);
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);
    return result.value("sats").toString().toLongLong();
}

Asset* Wallet::getOrCreateAsset(const QString& id)
{
    Q_ASSERT(m_network && m_network->isLiquid());
    QString key = id == "btc" ? "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d" : id;

    Asset* asset = m_assets.value(key);
    if (!asset) {
        asset = new Asset(key, this);
        m_assets.insert(key, asset);
    }
    return asset;
}

void Wallet::setSettings(const QJsonObject& settings)
{
    if (m_settings == settings) return;
    m_settings = settings;
    emit settingsChanged();

    if (m_logout_timer != -1 ) {
        killTimer(m_logout_timer);
        m_logout_timer = -1;
    }
    int altimeout = m_settings.value("altimeout").toInt();
    if (altimeout > 0) {
        m_logout_timer = startTimer(altimeout * 60 * 1000);
        qApp->installEventFilter(this);
    } else {
        qApp->removeEventFilter(this);
    }
}

bool Wallet::eventFilter(QObject* object, QEvent* event)
{
    if (event->type() == QEvent::KeyPress || event->type() == QEvent::MouseMove) {
        Q_ASSERT(m_logout_timer != -1);
        killTimer(m_logout_timer);
        int altimeout = m_settings.value("altimeout").toInt();
        m_logout_timer = startTimer(altimeout * 60 * 1000);
    }
    return QObject::eventFilter(object, event);
}

void Wallet::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == m_logout_timer) {
        disconnect();
    }
}

void Wallet::setLocked(bool locked)
{
    if (m_locked == locked) return;
    m_locked = locked;
    emit lockedChanged(m_locked);
}
