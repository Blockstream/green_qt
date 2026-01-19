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

#include "activitymanager.h"
#include "context.h"
#include "device.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"
#include "util.h"
#include "walletmanager.h"

#include <nlohmann/json.hpp>

Wallet::Wallet(QObject* parent)
    : QObject(parent)
{
}

Wallet::~Wallet()
{
}

void Wallet::disconnect()
{
    if (m_context) {
        if (m_context->device()) {
            auto activity = m_context->device()->logout();
            if (activity) ActivityManager::instance()->exec(activity);
        }
        m_context->deleteLater();
        setContext(nullptr);
    }
}

void Wallet::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
}

QString Wallet::id() const
{
    Q_ASSERT(!m_id.isEmpty());
    return m_id;
}

void Wallet::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();
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
        name = WalletManager::instance()->newWalletName();
    }
    if (m_name == name) return false;
    if (active_focus) return false;
    setName(name);
    if (m_name.isEmpty()) return false;
    save();
    return true;
}

void Wallet::save()
{
    Q_ASSERT(QThread::currentThread() == thread());
    Q_ASSERT(!m_id.isEmpty());
    if (!m_is_persisted) return;
    QJsonObject data({
        { "name", m_name },
        { "deployment", m_deployment },
        { "hashes", QJsonArray::fromStringList(m_hashes.values()) },
    });
    if (!m_xpub_hash_id.isEmpty()) {
        data.insert("xpub_hash_id", m_xpub_hash_id);
    }
    if (m_login) m_login->write(data);
    QFile file(GetDataFile("wallets2", m_id));
    bool result = file.open(QFile::WriteOnly | QFile::Truncate);
    Q_ASSERT(result);
    file.write(QJsonDocument(data).toJson());
    result = file.flush();
    Q_ASSERT(result);
}

void Wallet::setLogin(LoginData* login)
{
    if (m_login == login) return;
    if (m_login) m_login->deleteLater();
    m_login = login;
    emit loginChanged();
}

/*
void Wallet::setPinData(Network* network, const QByteArray& pin_data)
{
    if (m_network == network && m_pin_data == pin_data) return;
    m_network = network;
    m_pin_data = pin_data;
    emit hasPinDataChanged();
    resetLoginAttempts();
    save();
}
*/

QJsonObject Wallet::convert(const QJsonObject& value) const
{
    if (!m_context) return {};
    auto session = m_context->primarySession();
    if (!session) return {};
    auto details = Json::fromObject(value);
    GA_json* balance;
    int err = GA_convert_amount(session->m_session, details.get(), &balance);
    if (err != GA_OK) return {};
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);
    return result;
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker) const
{
    const auto session = m_context->primarySession();
    return formatAmount(amount, include_ticker, session->unit());
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker, const QString& unit) const
{
    if (!m_context) return {};
    const auto session = m_context->primarySession();
    const auto effective_unit = unit.isEmpty() ? session->unit() : unit;
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
        str += " " + ComputeDisplayUnit(session->network(), effective_unit);
    }
    return str;
}

/*
void Wallet::updateDeviceDetails(const QJsonObject& device_details)
{
    if (m_device_details == device_details) return;
    m_device_details = device_details;
    emit deviceDetailsChanged();
    save();
}
*/

void Wallet::setXPubHashId(const QString &xpub_hash_id)
{
    if (m_xpub_hash_id == xpub_hash_id) return;
    // Q_ASSERT(m_xpub_hash_id.isEmpty());
    m_xpub_hash_id = xpub_hash_id;
    emit xpubHashIdChanged();
    save();
}

LoginData::LoginData(Wallet* wallet)
    : QObject(wallet)
    , m_wallet(wallet)
{
}

void PinData::setAttempts(int attempts)
{
    if (m_attempts == attempts) return;
    m_attempts = attempts;
    emit attemptsChanged();
    m_wallet->save();
}

void PinData::resetAttempts()
{
    setAttempts(3);
}

void PinData::decrementAttempts()
{
    Q_ASSERT(m_attempts > 0);
    setAttempts(m_attempts - 1);
}

void PinData::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
}

void PinData::setPassphrase(bool passphrase)
{
    if (m_passphrase == passphrase) return;
    m_passphrase = passphrase;
    emit passphraseChanged();
    m_wallet->save();
}

void PinData::setData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    m_wallet->save();
}

bool PinData::write(QJsonObject& data)
{
    data.insert("pin", QJsonObject{
        { "network", m_network->id() },
        { "data", m_data },
        { "attempts", m_attempts },
        { "passphrase", m_passphrase },
    });
    return true;
}

bool PinData::read(const QJsonObject& data)
{
    const auto pin = data.value("pin").toObject();
    m_network = NetworkManager::instance()->network(pin.value("network").toString());
    m_data = pin.value("data").toObject();
    m_attempts = pin.value("attempts").toInt();
    m_passphrase = pin.value("passphrase").toBool();
    return true;
}

void DeviceData::setDevice(const QJsonObject& device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged();
}

bool DeviceData::write(QJsonObject& data)
{
    data.insert("device", m_device);
    return true;
}

bool DeviceData::read(const QJsonObject& data)
{
    m_device = data.value("device").toObject();
    return true;
}

void WatchonlyData::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
}

void WatchonlyData::setUsername(const QString& username)
{
    if (m_username == username) return;
    m_username = username;
    emit usernameChanged();
}

void WatchonlyData::setCoreDescriptors(const QStringList& core_descriptors)
{
    if (m_core_descriptors == core_descriptors) return;
    m_core_descriptors = core_descriptors;
    emit coreDescriptorsChanged();
}

void WatchonlyData::setExtendedPubkeys(const QStringList& extended_pubkeys)
{
    if (m_extended_pubkeys == extended_pubkeys) return;
    m_extended_pubkeys = extended_pubkeys;
    emit extendedPubkeysChanged();
}

bool WatchonlyData::write(QJsonObject& data)
{
    if (m_network->isElectrum() && !m_core_descriptors.isEmpty()) {
        data.insert("watchonly", QJsonObject{
            { "network", m_network->id() },
            { "core_descriptors", QJsonArray::fromStringList(m_core_descriptors) },
        });
        return true;
    }
    if (m_network->isElectrum() && !m_extended_pubkeys.isEmpty()) {
        data.insert("watchonly", QJsonObject{
            { "network", m_network->id() },
            { "extended_pubkeys", QJsonArray::fromStringList(m_extended_pubkeys) },
        });
        return true;
    }
    if (!m_network->isElectrum()) {
        data.insert("watchonly", QJsonObject{
            { "network", m_network->id() },
            { "username", m_username },
        });
        return true;
    }
    return false;
}

static QStringList ToStringList(const QJsonValue& input)
{
    QStringList list;
    if (!input.isArray()) return list;
    for (const auto value : input.toArray()) {
        list.append(value.toString());
    }
    return list;
}

bool WatchonlyData::read(const QJsonObject& data)
{
    auto watchonly = data.value("watchonly").toObject();
    m_network = NetworkManager::instance()->network(watchonly.value("network").toString());
    m_username = watchonly.value("username").toString();
    m_core_descriptors = ToStringList(watchonly.value("core_descriptors"));
    m_extended_pubkeys = ToStringList(watchonly.value("extended_pubkeys"));
    return true;
}
