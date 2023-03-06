#include "wallet.h"

#include <gdk.h>

#include <QDateTime>
#include <QDebug>
#include <QJsonObject>
#include <QLocale>
#include <QSettings>
#include <QTimer>
#include <QUuid>

#include <type_traits>

#include "account.h"
#include "asset.h"
#include "balance.h"
#include "device.h"
#include "ga.h"
#include "handler.h"
#include "json.h"
#include "loginhandler.h"
#include "network.h"
#include "resolver.h"
#include "session.h"
#include "util.h"
#include "walletmanager.h"

#include <nlohmann/json.hpp>

namespace {
void UpdateAsset(GA_session* session, Asset* asset)
{
    const auto id = asset->id().toStdString();

    const nlohmann::json params = {{ "assets_id", { id } }};
    nlohmann::json* output;

    const auto err = GA_get_assets(session, (const GA_json*) &params, (GA_json**) &output);
    Q_ASSERT(err == GA_OK);

    if (output->at("assets").contains(id)) {
        const auto data = output->at("assets").at(id);
        asset->setData(Json::toObject((GA_json*) &data));
    }
    // TODO: remove the following workaround after updating gdk to 0.0.58
    if (id == "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d") {
        asset->setIcon("qrc:/png/lbtc.png");
    } else if (output->at("icons").contains(id)) {
        const auto icon = output->at("icons").at(id).get<std::string>();
        asset->setIcon(QString("data:image/png;base64,") + QString::fromStdString(icon));
    }
    GA_destroy_json((GA_json*) output);
}
}

class ReloginHandler : public Handler
{
public:
    ReloginHandler(Session* session) : Handler(session) {}
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        QJsonObject hw_device, details;
        GA_login_user(session, Json::fromObject(hw_device).get(), Json::fromObject(details).get(), auth_handler);
    }
};

Wallet::Wallet(Network* network, const QString& hash_id, QObject* parent)
    : Entity(parent)
    , m_network(network)
    , m_hash_id(hash_id)
{
    QObject::connect(this, &Wallet::activitiesChanged, this, &Wallet::updateReady);
    QObject::connect(this, &Wallet::authenticationChanged, this, &Wallet::updateReady);
}

void Wallet::disconnect()
{
    Q_ASSERT(m_authentication == Authenticated);

    if (m_logout_timer != -1) {
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
        if (m_authentication == Authenticated) {
            auto handler = new ReloginHandler(m_session);
            QObject::connect(handler, &Handler::done, this, [=] {
                handler->deleteLater();
            });
            handler->exec();
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

    qDebug() << "unhandled event" << event;
}

QJsonObject Wallet::events() const
{
    return m_events;
}

void Wallet::reload(bool refresh_accounts)
{
    if (m_network->isLiquid()) {
        refreshAssets();
    }

    auto handler = new GetSubAccountsHandler(m_session, refresh_accounts);
    QObject::connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();

        m_accounts.clear();
        for (auto value : handler->subAccounts()) {
            QJsonObject data = value.toObject();
            Account* account = getOrCreateAccount(data);
            account->reload();
            m_accounts.append(account);
        }

        emit accountsChanged();

        updateConfig();
        updateEmpty();

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
    });
    QObject::connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}

class RefreshAssetsHandler : public Handler
{
public:
    RefreshAssetsHandler(Session* session)
        : Handler(session)
    {
    }
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        Q_UNUSED(auth_handler);
        auto params = Json::fromObject({
            { "assets", true },
            { "icons", true },
        });
        int rc = GA_refresh_assets(session, params.get());
        if (rc != GA_OK) return;
    }
};

void Wallet::refreshAssets()
{
    Q_ASSERT(m_network->isLiquid());

    auto handler = new RefreshAssetsHandler(m_session);
    handler->exec();

    connect(handler, &Handler::done, this, [=] {
        handler->deleteLater();

        for (auto asset : m_assets.values()) {
            UpdateAsset(m_session->m_session, asset);
        }

        for (auto account : m_accounts) {
            account->updateBalance();
        }
    });
    connect(handler, &Handler::error, this, [=] {
        handler->deleteLater();
    });
}

bool Wallet::rename(QString name, bool active_focus)
{
    if (!active_focus) name = name.trimmed();
    if (name.isEmpty() && !active_focus) {
        if (m_network) {
            name = WalletManager::instance()->newWalletName(m_network);
        } else {
            name = "My Wallet";
        }
    }
    if (m_name == name) return false;
    if (active_focus) return false;
    setName(name);
    if (m_name.isEmpty()) return false;
    save();
    return true;
}

void Wallet::setWatchOnly(const QString& username, const QString& password)
{
    Q_ASSERT(!m_watch_only);
    int rc = GA_set_watch_only(m_session->m_session, username.toUtf8().constData(), password.toUtf8().constData());

    if (rc != GA_OK) {
        emit watchOnlyUpdateFailure();
        return;
    }

    m_username = username;
    emit usernameChanged(m_username);
    emit watchOnlyUpdateSuccess();
}

void Wallet::clearWatchOnly()
{
    setWatchOnly("", "");
}

void Wallet::updateConfig()
{
    if (m_watch_only) return;
    m_config = gdk::get_twofactor_config(m_session->m_session);
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
    m_currencies = gdk::get_available_currencies(m_session->m_session);
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
    if (m_login_attempts_remaining > 0 || !m_pin_data.isEmpty()) {
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
    setPinData({});
}

void Wallet::setPinData(const QByteArray& pin_data)
{
    if (m_pin_data == pin_data) return;
    m_pin_data = pin_data;
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
        str.remove(QRegularExpression("\\.?0+$"));
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
        UpdateAsset(m_session->m_session, asset);
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
        account = new Account(data, m_network, this);
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
    reload(true);
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

void Wallet::resetLoginAttempts()
{
    if (m_login_attempts_remaining < 3) {
        m_login_attempts_remaining = 3;
        emit loginAttemptsRemainingChanged(m_login_attempts_remaining);
        save();
    }
}

void Wallet::decrementLoginAttempts()
{
    Q_ASSERT(m_login_attempts_remaining > 0);
    --m_login_attempts_remaining;
    emit loginAttemptsRemainingChanged(m_login_attempts_remaining);
    if (m_login_attempts_remaining == 0) {
        m_pin_data.clear();
        emit hasPinDataChanged();
        m_session->setActive(false);
    }
    save();
}

void Wallet::setSettings(const QJsonObject& settings)
{
    if (m_settings == settings) return;
    qDebug() << Q_FUNC_INFO << settings;

    m_settings = settings;
    updateDisplayUnit();
    emit settingsChanged();

    if (m_logout_timer != -1) {
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

void EncryptWithPinHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    const auto details= Json::fromObject({
        { "pin", m_pin },
        { "plaintext", m_plaintext }
    });
    GA_encrypt_with_pin(session, details.get(), auth_handler);
}

EncryptWithPinHandler::EncryptWithPinHandler(const QJsonObject& plaintext, const QString& pin, Session* session)
    : Handler(session)
    , m_plaintext(plaintext)
    , m_pin(pin)
{
}

QByteArray EncryptWithPinHandler::pinData() const
{
    auto pin_data = result().value("result").toObject().value("pin_data").toObject();
    return QJsonDocument(pin_data).toJson();
}

GetCredentialsHandler::GetCredentialsHandler(Session* session)
    : Handler(session)
{
}

QJsonObject GetCredentialsHandler::credentials() const
{
    return result().value("result").toObject();
}

QString GetCredentialsHandler::mnemonic() const
{
    return credentials().value("mnemonic").toString();
}

void GetCredentialsHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    auto details = Json::fromObject({{"password", ""}});
    GA_get_credentials(session, details.get(), auth_handler);
}
