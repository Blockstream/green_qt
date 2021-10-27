#include "ga.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"
#include "util.h"
#include "wallet.h"
#include "walletmanager.h"

#include <QDir>
#include <QJsonDocument>
#include <QSet>
#include <QSettings>
#include <QStandardPaths>
#include <QUrl>
#include <QUrlQuery>
#include <QDirIterator>
#include <QUuid>

#include <gdk.h>

static WalletManager* g_wallet_manager{nullptr};

WalletManager::WalletManager()
{
    Q_ASSERT(!g_wallet_manager);
    g_wallet_manager = this;

    auto config = Json::fromObject({{ "datadir", GetDataDir("gdk") }});
    GA_init(config.get());

    QDirIterator it(GetDataDir("wallets"));
    while (it.hasNext()) {
        QFile file(it.next());
        if (!file.open(QFile::ReadOnly)) continue;
        QJsonParseError parser_error;
        auto doc = QJsonDocument::fromJson(file.readAll(), &parser_error);
        if (parser_error.error != QJsonParseError::NoError) continue;
        if (!doc.isObject()) continue;
        auto data = doc.object();
        auto network = NetworkManager::instance()->network(data.value("network").toString());
        if (!network) continue;
        Wallet* wallet = new Wallet(network, this);
        wallet->m_is_persisted = true;
        wallet->m_id = QFileInfo(file).baseName();
        if (data.contains("pin_data")) {
            wallet->m_pin_data = QByteArray::fromBase64(data.value("pin_data").toString().toLocal8Bit());
            wallet->m_login_attempts_remaining = data.value("login_attempts_remaining").toInt();
        }
        if (data.contains("hash_id")) {
            wallet->m_hash_id = data.value("hash_id").toString();
        }
        if (data.contains("username")) {
            wallet->m_watch_only = true;
            wallet->m_username = data.value("username").toString();
        }
        if (data.contains("device_details")) {
            wallet->m_device_details = data.value("device_details").toObject();
        }
        wallet->m_name = data.value("name").toString();
        addWallet(wallet);
    }
}

WalletManager::~WalletManager()
{
}

WalletManager* WalletManager::instance()
{
    Q_ASSERT(g_wallet_manager);
    return g_wallet_manager;
}

void WalletManager::addWallet(Wallet* wallet)
{
    if (m_wallets.contains(wallet)) return;
    m_wallets.append(wallet);
    emit changed();
    emit walletAdded(wallet);

    // Not persisted wallets should be removed when session is lost
    connect(wallet, &Wallet::sessionChanged, this, [=](Session* session) {
        if (!session && !wallet->isPersisted()) {
            removeWallet(wallet);
        }
    });
}

Wallet* WalletManager::createWallet(Network* network)
{
    auto wallet = new Wallet(network, this);
    wallet->m_id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    return wallet;
}

Wallet *WalletManager::restoreWallet(Network *network)
{
    auto wallet = createWallet(network);
    wallet->m_is_persisted = true;
    wallet->m_restoring = true;
    return wallet;
}

void WalletManager::insertWallet(Wallet* wallet)
{
    Q_ASSERT(!wallet->m_id.isEmpty() && !wallet->m_pin_data.isEmpty());
    QFile file(GetDataFile("wallets", wallet->m_id));
    addWallet(wallet);
    wallet->save();
}

void WalletManager::removeWallet(Wallet* wallet)
{
    emit aboutToRemove(wallet);
    // Q_ASSERT(wallet->connection() == Wallet::Disconnected);
    m_wallets.removeOne(wallet);
    emit changed();
    if (wallet->isPersisted()) {
        bool result = QFile::remove(GetDataFile("wallets", wallet->m_id));
        Q_ASSERT(result);
    }
    wallet->deleteLater();
}

QQmlListProperty<Wallet> WalletManager::wallets()
{
    return QQmlListProperty<Wallet>(this, &m_wallets,
        [](QQmlListProperty<Wallet>* property) { return static_cast<QVector<Wallet*>*>(property->data)->size(); },
    [](QQmlListProperty<Wallet>* property, int index) { return static_cast<QVector<Wallet*>*>(property->data)->at(index); });
}

QString WalletManager::newWalletName(Network* network) const
{
    if (!network) return {};
    return uniqueWalletName(QString("My %1 Wallet").arg(network->displayName()));
}

QString WalletManager::uniqueWalletName(const QString& base) const
{
    QSet<QString> names;
    for (Wallet* wallet : m_wallets) {
        if (wallet->name().startsWith(base)) names.insert(wallet->name());
    }
    int n = 0;
    QString name = base;
    while (names.contains(name)) {
        name = QString("%1 %2").arg(base).arg(++n);
    }
    return name;
}

QJsonObject WalletManager::parseUrl(const QString &url)
{
    QJsonObject r;
    QUrl res(url);
    QUrlQuery q(res);

    r.insert("address", res.path());
    if (q.hasQueryItem("amount")) {
        r.insert("amount", q.queryItemValue("amount"));
    }
    if (q.hasQueryItem("message")) {
        r.insert("message", q.queryItemValue("message"));
    }

    return r;
}

Wallet* WalletManager::wallet(const QString& id) const
{
    for (auto wallet : m_wallets) {
        if (wallet->id() == id) {
            return wallet;
        }
    }
    return nullptr;
}

Wallet *WalletManager::walletWithHashId(const QString &hash_id, bool watch_only) const
{
    for (auto wallet : m_wallets) {
        if (wallet->m_hash_id == hash_id && wallet->m_watch_only == watch_only) {
            return wallet;
        }
    }
    return nullptr;
}
