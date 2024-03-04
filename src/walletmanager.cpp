#include "walletmanager.h"

#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QJsonDocument>
#include <QSet>
#include <QSettings>
#include <QStandardPaths>
#include <QTemporaryFile>
#include <QUuid>

#include "ga.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"
#include "util.h"
#include "wallet.h"

static WalletManager* g_wallet_manager{nullptr};

bool ReadWalletRecord(const QString& path, QString& id, QJsonObject& data)
{
    QFile file(path);
    if (!file.open(QFile::ReadOnly)) return false;
    QJsonParseError parser_error;
    auto doc = QJsonDocument::fromJson(file.readAll(), &parser_error);
    if (parser_error.error != QJsonParseError::NoError) return false;
    if (!doc.isObject()) return false;
    data = doc.object();
    id = QFileInfo(file).baseName();
    return true;
}

WalletManager::WalletManager()
{
    Q_ASSERT(!g_wallet_manager);
    g_wallet_manager = this;
}

void WalletManager::loadWallets()
{
    if (!ExistsDataDir("wallets2")) {
        qDebug() << "migrate wallets";
        QDirIterator it(GetDataDir("wallets"));
        while (it.hasNext()) {
            QString id;
            QJsonObject data;
            if (!ReadWalletRecord(it.next(), id, data)) continue;

            auto add = [=](const QString& type, const QJsonObject& login) {
                auto deployment = data.value("deployment").toString("mainnet");
                const auto new_id = QUuid::createUuid().toString(QUuid::WithoutBraces);
                QJsonArray hashes;
                const auto hash_id = data.value("hash_id").toString();
                if (!hash_id.isEmpty()) hashes.append(hash_id);
                const auto content = QJsonObject{
                    { "id", new_id },
                    { "name", data.value("name") },
                    { "xpub_hash_id", data.value("xpub_hash_id").toString() },
                    { "deployment", deployment },
                    { "incognito", data.value("incognito").toBool(false) },
                    { "hashes", hashes },
                    { type, login },
                };

                QFile file(GetDataFile("wallets2", new_id));
                bool result = file.open(QFile::WriteOnly | QFile::Truncate);
                Q_ASSERT(result);
                file.write(QJsonDocument(content).toJson());
                result = file.flush();
            };

            if (data.contains("pin_data") && data.contains("network")) {
                const auto pin_data = data.value("pin_data").toString();
                if (!pin_data.isEmpty()) {
                    add("pin", QJsonObject{
                        { "data", QJsonDocument::fromJson(QByteArray::fromBase64(pin_data.toLocal8Bit())).object() },
                        { "attempts", data.value("login_attempts_remaining").toInt() },
                        { "network", data.value("network").toString() },
                    });
                }
            }

            if (data.contains("device_details")) {
                add("device", data.value("device_details").toObject());
            }

            if (data.contains("username") && data.contains("network")) {
                add("watchonly", QJsonObject{
                    { "username", data.value("username").toString() },
                    { "network", data.value("network").toString() },
                });
            }
        }
    }

    QDirIterator it(GetDataDir("wallets2"));
    while (it.hasNext()) {
        QString id;
        QJsonObject data;
        if (!ReadWalletRecord(it.next(), id, data)) continue;

        Wallet* wallet = new Wallet(this);
        wallet->m_is_persisted = true;
        wallet->m_id = id;
        wallet->m_deployment = data.value("deployment").toString("mainnet");
        wallet->m_name = data.value("name").toString();
        wallet->m_xpub_hash_id = data.value("xpub_hash_id").toString();
        for (const auto hash : data.value("hashes").toArray()) {
            wallet->m_hashes.insert(hash.toString());
        }

        if (data.contains("pin")) {
            auto pin = new PinData(wallet);
            pin->read(data);
            wallet->setLogin(pin);
        } else if (data.contains("watchonly")) {
            auto watchonly = new WatchonlyData(wallet);
            watchonly->read(data);
            wallet->setLogin(watchonly);
        } else if (data.contains("device")) {
            auto device = new DeviceData(wallet);
            device->read(data);
            wallet->setLogin(device);
        } else {
            Q_UNREACHABLE();
        }

        addWallet(wallet);
    }
}

WalletManager::~WalletManager()
{
    g_wallet_manager = nullptr;
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

    // Not persisted wallets should be removed when context is lost
    connect(wallet, &Wallet::contextChanged, this, [=] {
        if (!wallet->context() && !wallet->isPersisted()) {
            removeWallet(wallet);
        }
    });
}

Wallet* WalletManager::createWallet()
{
    auto wallet = new Wallet(this);
    wallet->m_id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    return wallet;
}

void WalletManager::insertWallet(Wallet* wallet)
{
    Q_ASSERT(!wallet->m_id.isEmpty());
    QFile file(GetDataFile("wallets2", wallet->m_id));
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
        bool result = QFile::remove(GetDataFile("wallets2", wallet->m_id));
        Q_ASSERT(result);
    }
    wallet->deleteLater();
}

QQmlListProperty<Wallet> WalletManager::wallets()
{
    return {
      this, &m_wallets,
      [](QQmlListProperty<Wallet>* property) { return static_cast<QVector<Wallet*>*>(property->data)->size(); },
      [](QQmlListProperty<Wallet>* property, qsizetype index) { return static_cast<QVector<Wallet*>*>(property->data)->at(index); }};
}

QString WalletManager::newWalletName() const
{
    return uniqueWalletName("My Wallet");
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

QStringList WalletManager::generateMnemonic(int size)
{
    return gdk::generate_mnemonic(size);
}

void WalletManager::printBackupTemplate()
{
    QFile src(":/pdf/recovery-phrase-backup-template-12-words.pdf");
    src.open(QFile::ReadOnly);
    auto data = src.readAll();

    QTemporaryFile file;
    file.setAutoRemove(false);
    file.setFileTemplate(QDir::tempPath() + "/recovery-phrase-backup-template-12-words-XXXXXX.pdf");
    file.open();
    file.write(data);
    file.close();

    QDesktopServices::openUrl(QUrl::fromLocalFile(file.fileName()));
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
/*
    for (auto wallet : m_wallets) {
        if (wallet->m_hash_id == hash_id && wallet->m_watch_only == watch_only) {
            return wallet;
        }
    }
*/
    return nullptr;
}
