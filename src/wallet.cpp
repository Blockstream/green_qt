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

#include "context.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "util.h"
#include "walletmanager.h"

#include <nlohmann/json.hpp>

Wallet::Wallet(Network* network, const QString& hash_id, QObject* parent)
    : QObject(parent)
    , m_network(network)
    , m_hash_id(hash_id)
{
}

void Wallet::disconnect()
{
    if (m_context) {
        m_context->deleteLater();
        setContext(nullptr);
    }
}

Wallet::~Wallet()
{
}

void Wallet::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
    if (m_context) {
        m_context->setParent(this);
    }
}

Session *Wallet::session() const { return m_context->session(); }

QString Wallet::id() const
{
    Q_ASSERT(!m_id.isEmpty());
    return m_id;
}

void Wallet::setName(const QString& name)
{
    m_name = name;
    emit nameChanged(m_name);
}

QJsonObject Wallet::pinData() const
{
    if (m_pin_data.isNull()) return {};
    return QJsonDocument::fromJson(m_pin_data).object();
}

void Wallet::reload(bool refresh_accounts)
{
    /*
    auto handler = new GetSubAccountsHandler(session(), refresh_accounts);
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

        if (!m_watch_only) {
            char* data;
            GA_get_watch_only_username(session()->m_session, &data);
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
    */
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

QJsonObject Wallet::convert(const QJsonObject& value) const
{
    auto details = Json::fromObject(value);
    GA_json* balance;
    int err = GA_convert_amount(session()->m_session, details.get(), &balance);
    if (err != GA_OK) return {};
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);
    return result;
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker) const
{
    return formatAmount(amount, include_ticker, m_context->unit());
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker, const QString& unit) const
{
    Q_ASSERT(m_network);
    const auto effective_unit = unit.isEmpty() ? m_context->unit() : unit;
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

void Wallet::updateDeviceDetails(const QJsonObject& device_details)
{
    if (m_device_details == device_details) return;
    m_device_details = device_details;
    emit deviceDetailsChanged();
    save();
}

qint64 Wallet::amountToSats(const QString& amount) const
{
    return parseAmount(amount, m_context->unit());
}

qint64 Wallet::parseAmount(const QString& amount, const QString& unit) const
{
    if (amount.isEmpty()) return 0;
    QString sanitized_amount = amount;
    sanitized_amount.replace(',', '.');
    auto details = Json::fromObject({{ unit == "\u00B5BTC" ? "ubtc" : unit.toLower(), sanitized_amount }});
    GA_json* balance;
    int err = GA_convert_amount(session()->m_session, details.get(), &balance);
    if (err != GA_OK) return 0;
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);
    return result.value("sats").toString().toLongLong();
}

void Wallet::updateHashId(const QString& hash_id)
{
    if (m_hash_id == hash_id) return;
    if (!m_hash_id.isEmpty()) {
        qWarning() << Q_FUNC_INFO << "new:" << hash_id << "current:" << m_hash_id;
    }
    m_hash_id = hash_id;
    save();
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
    }
    save();
}
