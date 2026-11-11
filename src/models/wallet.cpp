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
#include "device.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"
#include "util.h"
#include "walletmanager.h"

#include <nlohmann/json.hpp>

class WalletPrivate
{
public:
    WalletPrivate(const QString& id) : id(id) {}
    const QString id;
    bool is_persisted{false};
    QString deployment;
    QString name;
    LoginData* login{nullptr};
    QString xpub_hash_id;
    QSet<QString> hashes;
    bool lightning_enabled{false};
    QString amp2_wid;
    bool amp2_hidden{false};
    QString amp2_name;
    Context* context{nullptr};
};

Wallet::Wallet(const QString& id, QObject* parent)
    : QObject(parent)
    , d_ptr(new WalletPrivate(id))
{
}

Wallet::~Wallet()
{
    delete d_ptr;
}

void Wallet::disconnect()
{
    Q_D(Wallet);
    if (d->context) {
        if (d->context->device()) {
            auto task = d->context->device()->logout();
            if (task) d->context->device()->exec(task);
        }
        d->context->deleteLater();
        setContext(nullptr);
    }
}

Context* Wallet::context() const
{
    Q_D(const Wallet);
    return d->context;
}

void Wallet::setContext(Context* context)
{
    Q_D(Wallet);
    if (d->context == context) return;
    d->context = context;
    emit contextChanged();
}

QString Wallet::id() const
{
    Q_D(const Wallet);
    Q_ASSERT(!d->id.isEmpty());
    return d->id;
}

QString Wallet::deployment() const
{
    Q_D(const Wallet);
    return d->deployment;
}

void Wallet::setDeployment(const QString& deployment)
{
    Q_D(Wallet);
    d->deployment = deployment;
}

bool Wallet::isPersisted() const
{
    Q_D(const Wallet);
    return d->is_persisted;
}

void Wallet::setPersisted(bool persisted)
{
    Q_D(Wallet);
    if (d->is_persisted == persisted) return;
    d->is_persisted = persisted;
    emit isPersistedChanged();
}

QString Wallet::name() const
{
    Q_D(const Wallet);
    return d->name;
}

void Wallet::setName(const QString& name)
{
    Q_D(Wallet);
    if (d->name == name) return;
    d->name = name;
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
            GA_get_watch_only_username(session()->m_session.get(), &data);
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
    Q_D(Wallet);
    if (!active_focus) name = name.trimmed();
    if (name.isEmpty() && !active_focus) {
        name = WalletManager::instance()->newWalletName();
    }
    if (d->name == name) return false;
    if (active_focus) return false;
    setName(name);
    if (d->name.isEmpty()) return false;
    save();
    return true;
}

void Wallet::read(const QJsonObject& data)
{
    Q_D(Wallet);
    d->deployment = data.value("deployment").toString("mainnet");
    d->name = data.value("name").toString();
    d->xpub_hash_id = data.value("xpub_hash_id").toString();
    d->lightning_enabled = data.value("lightning_enabled").toBool(false);
    const auto amp2 = data.value("amp2").toObject();
    d->amp2_wid = amp2.value("wid").toString(data.value("amp2_wid").toString());
    d->amp2_hidden = amp2.value("hidden").toBool(false);
    d->amp2_name = amp2.value("name").toString();
    for (const auto hash : data.value("hashes").toArray()) {
        d->hashes.insert(hash.toString());
    }
}

void Wallet::save()
{
    Q_D(Wallet);
    Q_ASSERT(QThread::currentThread() == thread());
    Q_ASSERT(!d->id.isEmpty());
    if (!d->is_persisted) return;
    QJsonObject data({
        { "name", d->name },
        { "deployment", d->deployment },
        { "hashes", QJsonArray::fromStringList(d->hashes.values()) },
        { "lightning_enabled", d->lightning_enabled },
    });
    if (!d->xpub_hash_id.isEmpty()) {
        data.insert("xpub_hash_id", d->xpub_hash_id);
    }
    QJsonObject amp2;
    if (!d->amp2_wid.isEmpty()) {
        amp2.insert("wid", d->amp2_wid);
    }
    if (d->amp2_hidden) {
        amp2.insert("hidden", true);
    }
    if (!d->amp2_name.isEmpty()) {
        amp2.insert("name", d->amp2_name);
    }
    if (!amp2.isEmpty()) {
        data.insert("amp2", amp2);
    }
    if (d->login) d->login->write(data);
    QFile file(GetDataFile("wallets2", d->id));
    bool result = file.open(QFile::WriteOnly | QFile::Truncate);
    Q_ASSERT(result);
    file.write(QJsonDocument(data).toJson());
    result = file.flush();
    Q_ASSERT(result);
}

LoginData* Wallet::login() const
{
    Q_D(const Wallet);
    return d->login;
}

void Wallet::setLogin(LoginData* login)
{
    Q_D(Wallet);
    if (d->login == login) return;
    if (d->login) d->login->deleteLater();
    d->login = login;
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
    Q_D(const Wallet);
    if (!d->context) return {};
    auto session = d->context->primarySession();
    if (!session) return {};
    auto details = Json::fromObject(value);
    GA_json* balance;
    int err = GA_convert_amount(session->m_session.get(), details.get(), &balance);
    if (err != GA_OK) return {};
    QJsonObject result = Json::toObject(balance);
    GA_destroy_json(balance);
    return result;
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker) const
{
    Q_D(const Wallet);
    const auto session = d->context->primarySession();
    return formatAmount(amount, include_ticker, session->unit());
}

QString Wallet::formatAmount(qint64 amount, bool include_ticker, const QString& unit) const
{
    Q_D(const Wallet);
    if (!d->context) return {};
    const auto session = d->context->primarySession();
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

void Wallet::addHash(const QString& hash)
{
    Q_D(Wallet);
    d->hashes.insert(hash);
}

QString Wallet::xpubHashId() const
{
    Q_D(const Wallet);
    return d->xpub_hash_id;
}

void Wallet::setXPubHashId(const QString &xpub_hash_id)
{
    Q_D(Wallet);
    if (d->xpub_hash_id == xpub_hash_id) return;
    d->xpub_hash_id = xpub_hash_id;
    emit xpubHashIdChanged();
    save();
}

bool Wallet::lightningEnabled() const
{
    Q_D(const Wallet);
    return d->lightning_enabled;
}

void Wallet::setLightningEnabled(bool enabled)
{
    Q_D(Wallet);
    if (d->lightning_enabled == enabled) return;
    d->lightning_enabled = enabled;
    emit lightningEnabledChanged();
    save();
}

QString Wallet::amp2Wid() const
{
    Q_D(const Wallet);
    return d->amp2_wid;
}

void Wallet::setAmp2Wid(const QString& wid)
{
    Q_D(Wallet);
    if (d->amp2_wid == wid) return;
    d->amp2_wid = wid;
    save();
}

bool Wallet::amp2Hidden() const
{
    Q_D(const Wallet);
    return d->amp2_hidden;
}

void Wallet::setAmp2Hidden(bool hidden)
{
    Q_D(Wallet);
    if (d->amp2_hidden == hidden) return;
    d->amp2_hidden = hidden;
    save();
}

QString Wallet::amp2Name() const
{
    Q_D(const Wallet);
    return d->amp2_name;
}

void Wallet::setAmp2Name(const QString& name)
{
    Q_D(Wallet);
    if (d->amp2_name == name) return;
    d->amp2_name = name;
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
