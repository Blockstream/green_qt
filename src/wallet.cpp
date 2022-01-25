#include "account.h"
#include "asset.h"
#include "balance.h"
#include "ga.h"
#include "device.h"
#include "json.h"
#include "createaccounthandler.h"
#include "loginhandler.h"
#include "network.h"
#include "util.h"
#include "wallet.h"
#include "resolver.h"
#include "handler.h"
#include "session.h"
#include "walletmanager.h"

#include <type_traits>

#include <QDateTime>
#include <QDebug>
#include <QJsonObject>
#include <QLocale>
#include <QSettings>
#include <QTimer>
#include <QUuid>

#include <gdk.h>


namespace {
QByteArray getMnemonicPassphrase(GA_session* session)
{
    char* data;
    int err = GA_get_mnemonic_passphrase(session, "", &data);
    Q_ASSERT(err == GA_OK);
    QByteArray mnemonic(data);
    GA_destroy_string(data);
    return mnemonic;
}
QByteArray pinDataForNewPin(GA_session* session, const QByteArray& pin)
{
    const auto mnemonic = getMnemonicPassphrase(session);
    GA_json* data;
    int err = GA_set_pin(session, mnemonic.constData(), pin.constData(), "greenqt", &data);
    Q_ASSERT(err == GA_OK);
    auto pin_data = Json::jsonToString(data);
    err = GA_destroy_json(data);
    Q_ASSERT(err == GA_OK);
    return pin_data;
}
} // namespace

Wallet::Wallet(Network* network, QObject *parent)
    : Entity(parent)
    , m_network(network)
{
    QObject::connect(this, &Wallet::activitiesChanged, this, &Wallet::updateReady);
    QObject::connect(this, &Wallet::authenticationChanged, this, &Wallet::updateReady);
}

void Wallet::disconnect()
{
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

    setAuthentication(Unauthenticated);

    if (m_session) {
        auto session = m_session.get();
        m_session = nullptr;
        emit sessionChanged(nullptr);
        delete session;
    }

    qDeleteAll(accounts);
    qDeleteAll(m_assets.values());
    m_assets.clear();
}

Wallet::~Wallet()
{
    if (m_session) {
        auto session = m_session.get();
        m_session = nullptr;
        emit sessionChanged(nullptr);
        delete session;
    }
}

QString Wallet::id() const
{
    Q_ASSERT(!m_id.isEmpty() || m_device);
    return m_id;
}

void Wallet::setName(const QString& name)
{
    m_name = name;
    emit nameChanged(m_name);
}

void Wallet::updateReady()
{
    if (m_ready) {
        if (isAuthenticated()) return;
        m_ready = false;
    } else {
        if (hasActivities()) return;
        if (!isAuthenticated()) return;
        m_ready = true;
    }
    emit readyChanged(m_ready);
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
    return { this, &m_accounts };
}

void Wallet::handleNotification(const QJsonObject &notification)
{
    QString event = notification.value("event").toString();
    Q_ASSERT(!event.isEmpty());

    QJsonValue data = notification.value(event);

    if (data.isObject()) emit this->notification(event, data.toObject());

    m_events.insert(event, data);
    emit eventsChanged(m_events);

    if (event == "network") {
        const bool login_required = data.toObject().value("login_required").toBool();
        if (login_required) {
            setAuthentication(Unauthenticated);
        }
        return;
    }

    if (event == "transaction") {
        QJsonObject transaction = data.toObject();
        for (auto pointer : transaction.value("subaccounts").toArray()) {
            auto account = m_accounts_by_pointer.value(pointer.toInt());
            if (account) account->handleNotification(notification);
        }
        updateEmpty();
        return;
    }

    if (event == "settings") {
        setSettings(data.toObject());
        return;
    }

    if (event == "twofactor_reset") {
        setLocked(data.toObject().value("is_active").toBool());
        return;
    }

    if (event == "block") {
        setBlockHeight(data.toObject().value("block_height").toInt());
        for (auto account : m_accounts) {
            account->handleNotification(notification);
        }
        return;
    }
}

QJsonObject Wallet::events() const
{
    return m_events;
}

QStringList Wallet::mnemonic() const
{
    QStringList result;
    char* mnemonic = nullptr;
    int err = GA_get_mnemonic_passphrase(m_session->m_session, "", &mnemonic);
    Q_ASSERT(err == GA_OK);
    result = QString(mnemonic).split(' ');
    GA_destroy_string(mnemonic);
    return result;
}

void Wallet::changePin(const QByteArray& pin)
{
    auto handler = new SetPinHandler(pin, m_session);
    QObject::connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();
        m_pin_data = handler->pinData();
        save();
    });
    handler->exec();
}

void Wallet::reload(bool refresh_accounts)
{
    if (m_network->isLiquid()) {
        // Load cached assets
        refreshAssets(false);
    }

    if (!m_update_accounts_activity) {
        m_update_accounts_activity = new WalletUpdateAccountsActivity(this, this);
        pushActivity(m_update_accounts_activity);
    }

    auto handler = new GetSubAccountsHandler(m_session, refresh_accounts);
    QObject::connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();
        const bool create_segwit = m_network->isElectrum();
        bool has_segwit = false;

        m_accounts.clear();
        for (auto value : handler->subAccounts()) {
            QJsonObject data = value.toObject();
            Account* account = getOrCreateAccount(data);
            account->reload();
            has_segwit |= account->type() == "p2wpkh";
            m_accounts.append(account);
        }

        if (m_restoring && create_segwit && !has_segwit) {
            auto handler = new CreateAccountHandler({{ "name", "Segwit Account" }, { "type", "p2wpkh" }}, m_session);
            QObject::connect(handler, &Handler::done, this, [=] {
                handler->deleteLater();
                reload(false);
            });
            handler->exec();
            return;
        }

        emit accountsChanged();

        updateConfig();
        updateEmpty();

        if (m_network->isLiquid()) {
            // Update cached assets
            refreshAssets(true);
        }

        if (!m_watch_only) {
            char* data;
            GA_get_watch_only_username(m_session->m_session, &data);
            auto username = QString::fromUtf8(data);
            GA_destroy_string(data);
            if (m_username != username) {
                m_username = username;
                emit usernameChanged(m_username);
            }
        }

        m_update_accounts_activity->finish();
        m_update_accounts_activity->deleteLater();
        m_update_accounts_activity = nullptr;
    });
    QObject::connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}

class RefreshAssetsHandler : public Handler
{
public:
    const bool m_refresh;
    QJsonObject m_assets;

    RefreshAssetsHandler(bool refresh, Session* session)
        : Handler(session)
        , m_refresh(refresh)
    {
    }
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        Q_UNUSED(auth_handler);
        auto params = Json::fromObject({
            { "assets", true },
            { "icons", true },
            { "refresh", m_refresh }
        });
        GA_json* output;
        int rc = GA_refresh_assets(session, params.get(), &output);
        if (rc != GA_OK) return;

        m_assets = Json::toObject(output);
        rc = GA_destroy_json(output);
        Q_ASSERT(rc == GA_OK);
    }
};

void Wallet::refreshAssets(bool refresh)
{
    Q_ASSERT(m_network->isLiquid());

    auto activity = new WalletRefreshAssets(this, this);
    pushActivity(activity);

    auto handler = new RefreshAssetsHandler(refresh, m_session);
    handler->exec();

    connect(handler, &Handler::done, this, [this, handler, activity] {
        handler->deleteLater();

        if (handler->m_assets.empty()) {
            activity->fail();
            activity->deleteLater();
            return;
        }

        auto icons = handler->m_assets.value("icons").toObject();

        for (auto&& ref : handler->m_assets.value("assets").toObject()) {
            QString id = ref.toObject().value("asset_id").toString();
            if (id.isEmpty()) continue;
            Asset* asset = getOrCreateAsset(id);
            asset->setData(ref.toObject());
            if (icons.contains(id)) {
                asset->setIcon("data:image/png;base64," + icons.value(id).toString());
            }
        }

        for (auto account : m_accounts) {
            account->updateBalance();
        }

        activity->finish();
        activity->deleteLater();
    });
    connect(handler, &Handler::error, this, [handler, activity] {
        handler->deleteLater();
        activity->fail();
        activity->deleteLater();
    });
}

void Wallet::rename(QString name, bool active_focus)
{
    if (!active_focus) name = name.trimmed();
    if (name.isEmpty() && !active_focus) {
        if (m_network) {
            name = WalletManager::instance()->newWalletName(m_network);
        } else {
            name = "My Wallet";
        }
    }
    if (m_name == name) return;
    setName(name);
    if (!m_name.isEmpty()) save();
}

void Wallet::setWatchOnly(const QString& username, const QString& password)
{
    Q_ASSERT(!m_watch_only);
    int rc = GA_set_watch_only(m_session->m_session, username.toUtf8().constData(), password.toUtf8().constData());
    if (rc != GA_OK) return;
    m_username = username;
    emit usernameChanged(m_username);
}

void Wallet::updateConfig()
{
    if (m_watch_only) return;
    GA_json* config;
    int err = GA_get_twofactor_config(m_session->m_session, &config);
    Q_ASSERT(err == GA_OK);
    m_config = Json::toObject(config);
    GA_destroy_json(config);
    emit configChanged();

    setLocked(m_config.value("twofactor_reset").toObject().value("is_active").toBool());
}

void Wallet::updateSettings()
{
    const auto settings = gdk::get_settings(m_session->m_session);
    setSettings(settings);
}

QString ComputeDisplayUnit(Network* network, QString unit)
{
    if (network->isMainnet()) {
        if (unit == "btc") {
            unit = "BTC";
        }
    } else {
        if (unit == "BTC" || unit == "btc") {
            unit = "TEST";
        } else if (unit == "mBTC") {
            unit = "mTEST";
        } else if (unit == "\u00B5BTC") {
            unit = "\u00B5TEST";
        } else if (unit == "bits") {
            unit = "bTEST";
        } else if (unit == "sats") {
            unit = "sTEST";
        }
    }
    if (network->isLiquid()) unit.prepend("L-");
    return unit;
}

void Wallet::updateDisplayUnit()
{
    const auto display_unit = ComputeDisplayUnit(m_network, m_settings.value("unit").toString());
    if (m_display_unit == display_unit) return;
    m_display_unit = display_unit;
    emit displayUnitChanged(m_display_unit);
}

void Wallet::updateCurrencies()
{
    GA_json* currencies;
    int err = GA_get_available_currencies(m_session->m_session, &currencies);
    Q_ASSERT(err == GA_OK);
    m_currencies = Json::toObject(currencies);
    GA_destroy_json(currencies);
}

void Wallet::save()
{
    Q_ASSERT(QThread::currentThread() == thread());
    Q_ASSERT(!m_id.isEmpty());
    if (!m_is_persisted) return;
    QJsonObject data({
        { "version", 1 },
        { "name", m_name },
        { "network", m_network->id() }
    });
    if (m_watch_only) {
        data.insert("username", m_username);
    }
    if (!m_pin_data.isEmpty()) {
        data.insert("login_attempts_remaining", m_login_attempts_remaining);
        data.insert("pin_data", QString::fromLocal8Bit(m_pin_data.toBase64()));
    }
    if (!m_hash_id.isEmpty()) {
        data.insert("hash_id", m_hash_id);
    }
    if (!m_device_details.isEmpty()) {
        data.insert("device_details", m_device_details);
    }
    QFile file(GetDataFile("wallets", m_id));
    bool result = file.open(QFile::WriteOnly | QFile::Truncate);
    Q_ASSERT(result);
    file.write(QJsonDocument(data).toJson());
    result = file.flush();
    Q_ASSERT(result);
}

void Wallet::clearPinData()
{
    m_pin_data.clear();
    emit hasPinDataChanged();
    save();
}

void Wallet::updateEmpty()
{
    for (const auto& account : m_accounts_by_pointer.values()) {
        if (account->balance() > 0) {
            setEmpty(false);
            return;
        }
        for (const auto& balance : account->m_balances) {
            if (balance->amount() > 0) {
                setEmpty(false);
                return;
            }
        }
    }
    setEmpty(true);
}

void Wallet::setEmpty(bool empty)
{
    if (m_empty == empty) return;
    m_empty = empty;
    emit emptyChanged(m_empty);
}

void Wallet::setAuthentication(AuthenticationStatus authentication)
{
    if (m_authentication == authentication) return;
    qDebug() << "authentication change" << m_authentication << " -> " << authentication;
    m_authentication = authentication;
    emit authenticationChanged();
}

QJsonObject Wallet::convert(const QJsonObject& value) const
{
    auto details = Json::fromObject(value);
    GA_json* balance;
    int err = GA_convert_amount(m_session->m_session, details.get(), &balance);
    if (err != GA_OK) return {};
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
    const auto effective_unit = unit.isEmpty() ? m_settings.value("unit").toString() : unit;
    if (effective_unit.isEmpty()) return {};
    auto str = convert({{ "satoshi", amount }}).value(effective_unit == "\u00B5BTC" ? "ubtc" : effective_unit.toLower()).toString();
    auto val = str.toDouble();
    if (val == ((int64_t) val)) {
        str = QLocale::system().toString(val, 'f', 0);
    } else {
        str = QLocale::system().toString(val, 'f', 8);
        str.remove(QRegExp("\\.?0+$"));
    }
    if (include_ticker) {
        str += " " + ComputeDisplayUnit(m_network, effective_unit);
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
    int err = GA_convert_amount(m_session->m_session, details.get(), &balance);
    if (err != GA_OK) return 0;
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);
    return result.value("sats").toString().toLongLong();
}

Asset* Wallet::getOrCreateAsset(const QString& id)
{
    Q_ASSERT(m_network && m_network->isLiquid());
    Q_ASSERT(id != "btc");

    Asset* asset = m_assets.value(id);
    if (!asset) {
        asset = new Asset(id, this);
        m_assets.insert(id, asset);
    }
    return asset;
}

Account* Wallet::getOrCreateAccount(const QJsonObject& data)
{
    Q_ASSERT(data.contains("pointer"));
    const int pointer = data.value("pointer").toInt();
    Account* account = m_accounts_by_pointer.value(pointer);
    if (account) {
        account->update(data);
    } else {
        account = new Account(data, this);
        m_accounts_by_pointer.insert(pointer, account);
    }
    return account;
}

void Wallet::createSession()
{
    auto session = new Session(m_network, this);
    setSession(session);
}

void Wallet::setSession(Session* session)
{
    Q_ASSERT(session);
    Q_ASSERT(!m_session);
    m_session = session;
    m_session->setParent(this);
    Q_ASSERT(m_network == m_session->network());
    for (auto notification : session->events()) {
        handleNotification(notification);
    }
    m_session.track(QObject::connect(m_session, &Session::notificationHandled, this, &Wallet::handleNotification));
    emit sessionChanged(m_session);
}

void Wallet::setSession()
{
    setAuthentication(Authenticated);
    updateSettings();
    updateCurrencies();
    updateConfig();
    reload();
    updateReady();
}

void Wallet::setDevice(Device* device)
{
    if (m_device == device) return;
    m_device = device;
    if (m_device) {
        QObject::connect(m_device, &QObject::destroyed, this, [=] {
            setDevice(nullptr);
        });

        const auto device_details = m_device->details();
        if (m_device_details != device_details) {
            m_device_details = device_details;
            save();
            emit deviceDetailsChanged();
        }
    }
    emit deviceChanged(m_device);
}

void Wallet::updateHashId(const QString& hash_id)
{
    if (m_hash_id == hash_id) return;
    if (!m_hash_id.isEmpty()) {
        qWarning() << Q_FUNC_INFO << "new:" << hash_id << "current:" << m_hash_id;
    }
    m_hash_id = hash_id;
    save();
    updateReady();
}

void Wallet::setBlockHeight(int block_height)
{
    if (m_block_height == block_height) return;
    m_block_height = block_height;
    emit blockHeightChanged(m_block_height);
}

QString Wallet::getDisplayUnit(const QString& unit)
{
    return ComputeDisplayUnit(m_network, unit);
}

void Wallet::setSettings(const QJsonObject& settings)
{
    if (m_settings == settings) return;
    qDebug() << Q_FUNC_INFO << settings;

    m_settings = settings;
    updateDisplayUnit();
    emit settingsChanged();

    if (m_logout_timer != -1 ) {
        killTimer(m_logout_timer);
        m_logout_timer = -1;
    }
    if (!m_device) {
        int altimeout = m_settings.value("altimeout").toInt();
        if (altimeout > 0) {
            m_logout_timer = startTimer(altimeout * 60 * 1000);
            qApp->installEventFilter(this);
        } else {
            qApp->removeEventFilter(this);
        }
    }
}

bool Wallet::eventFilter(QObject* object, QEvent* event)
{
    switch (event->type()) {
    case QEvent::MouseButtonPress:
    case QEvent::MouseButtonRelease:
    case QEvent::MouseButtonDblClick:
    case QEvent::MouseMove:
    case QEvent::KeyPress:
    case QEvent::KeyRelease:
    case QEvent::Wheel:
    {
        Q_ASSERT(m_logout_timer != -1);
        killTimer(m_logout_timer);
        int altimeout = m_settings.value("altimeout").toInt();
        m_logout_timer = startTimer(altimeout * 60 * 1000);
        break;
    }
    default:
        break;
    }
    return QObject::eventFilter(object, event);
}

void Wallet::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == m_logout_timer) {
        if (m_device) return;
        disconnect();
    }
}

void Wallet::setLocked(bool locked)
{
    if (m_locked == locked) return;
    m_locked = locked;
    emit lockedChanged(m_locked);
}


WalletActivity::WalletActivity(Wallet* wallet, QObject* parent)
    : Activity(parent)
    , m_wallet(wallet)
{

}

WalletAuthenticateActivity::WalletAuthenticateActivity(Wallet* wallet, QObject* parent)
    : WalletActivity(wallet, parent)
{
}

void WalletAuthenticateActivity::exec()
{
}

WalletRefreshAssets::WalletRefreshAssets(Wallet* wallet, QObject* parent)
    : WalletActivity(wallet, parent)
{
}

void WalletRefreshAssets::exec()
{
}

WalletUpdateAccountsActivity::WalletUpdateAccountsActivity(Wallet* wallet, QObject* parent)
    : WalletActivity(wallet, parent)
{

}

void WalletUpdateAccountsActivity::exec()
{
}

WalletSignupActivity::WalletSignupActivity(Wallet *wallet, QObject *parent)
    : WalletActivity(wallet, parent)
{

}

void WalletSignupActivity::exec()
{

}

LoginWithPinController::LoginWithPinController(QObject* parent)
    : Entity(parent)
{
}

void LoginWithPinController::setWallet(Wallet* wallet)
{
    if (!m_wallet.update(wallet)) return;
    emit walletChanged(m_wallet);
    update();
}

void LoginWithPinController::setPin(const QByteArray &pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged(m_pin);
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

    auto activity = new WalletAuthenticateActivity(m_wallet, this);
    m_wallet->pushActivity(activity);

    auto handler = new LoginHandler(QJsonDocument::fromJson(m_wallet->m_pin_data).object(), QString::fromLocal8Bit(m_pin), m_session);
    handler->connect(handler, &Handler::done, this, [this, activity, handler] {
        handler->deleteLater();
        if (m_wallet->m_login_attempts_remaining < 3) {
            m_wallet->m_login_attempts_remaining = 3;
            m_wallet->save();
            emit m_wallet->loginAttemptsRemainingChanged(m_wallet->m_login_attempts_remaining);
        }
        m_wallet->updateHashId(handler->walletHashId());
        m_wallet->setAuthentication(Wallet::Authenticated);
        m_wallet->updateCurrencies();
        m_wallet->updateSettings();
        m_wallet->reload();
        m_wallet->updateConfig();
        activity->finish();
        activity->deleteLater();
    });
    handler->connect(handler, &Handler::error, this, [this, activity, handler] {
        handler->deleteLater();
        const auto error = handler->result().value("error").toString();
        if (error == "id_invalid_pin") {
            Q_ASSERT(m_wallet->m_login_attempts_remaining > 0);
            m_wallet->setAuthentication(Wallet::Unauthenticated);
            --m_wallet->m_login_attempts_remaining;
            m_wallet->save();
            emit m_wallet->loginAttemptsRemainingChanged(m_wallet->m_login_attempts_remaining);
            if (m_wallet->m_login_attempts_remaining == 0) m_session->setActive(false);
        }
        if (error.contains("exception:reconnect required")) {
            m_wallet->setAuthentication(Wallet::Unauthenticated);
            return;
        }
        qWarning() << "unhandled login_with_pin error";
        activity->fail();
        activity->deleteLater();
    });
    handler->exec();
}

void SetPinHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_UNUSED(auth_handler);
    m_pin_data = pinDataForNewPin(session, m_pin);
}

SetPinHandler::SetPinHandler(const QByteArray& pin, Session* session)
    : Handler(session)
    , m_pin(pin)
{
}

QByteArray SetPinHandler::pinData() const
{
    Q_ASSERT(!m_pin_data.isEmpty());
    return m_pin_data;
}

FeeEstimates::FeeEstimates(QObject* parent) :
    QObject(parent)
{
    connect(&m_update_timer, &QTimer::timeout, this, &FeeEstimates::update);
}

void FeeEstimates::setWallet(Wallet* wallet)
{
    if (!m_wallet.update(wallet)) return;
    if (m_wallet) {
        update();
        m_update_timer.start(120000);
    } else {
        m_update_timer.stop();
    }
}

void FeeEstimates::update()
{
    if (!m_wallet->session()) return;
    GA_json* estimates;
    if (GA_OK == GA_get_fee_estimates(m_wallet->session()->m_session, &estimates)) {
        const auto fees = Json::toObject(estimates).value("fees").toArray();
        GA_destroy_json(estimates);
        if (m_fees != fees) {
            m_fees = fees;
            emit feesChanged(m_fees);
        }
    }
}
