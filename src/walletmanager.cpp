#include "ga.h"
#include "json.h"
#include "network.h"
#include "util.h"
#include "wallet.h"
#include "walletmanager.h"

#include <QDir>
#include <QSet>
#include <QSettings>
#include <QStandardPaths>
#include <QUrl>
#include <QUrlQuery>

WalletManager::WalletManager()
{
    auto config = Json::fromObject({{ "datadir", GetDataDir("gdk") }});
    GA_init(config);
    GA_destroy_json(config);

    QSettings settings(GetDataFile("app", "wallets.ini"), QSettings::IniFormat);

    int count = settings.beginReadArray("wallets");

    for (int index = 0; index < count; ++index) {
        settings.setArrayIndex(index);

        auto pin_data = settings.value("pin_data").toByteArray();
        auto name = settings.value("name").toString();
        auto network = settings.value("network", "testnet").toString();
        int login_attempts_remaining = settings.value("login_attempts_remaining").toInt();

        Wallet* wallet = new Wallet(this);
        wallet->m_proxy = settings.value("proxy", "").toString();
        wallet->m_use_tor = settings.value("use_tor", false).toBool();
        wallet->m_index = index;
        wallet->m_pin_data = pin_data;
        wallet->m_name = name;
        wallet->m_network = NetworkManager::instance()->network(network);
        wallet->m_login_attempts_remaining = login_attempts_remaining;

        m_wallets.append(wallet);
    }

    settings.endArray();
}

WalletManager *WalletManager::instance()
{
    static WalletManager wallet_manager;
    return &wallet_manager;
}

Wallet* WalletManager::createWallet()
{
    return new Wallet(this);
}

void WalletManager::insertWallet(Wallet* wallet)
{
    m_wallets.append(wallet);
    emit walletsChanged();

    QMetaObject::invokeMethod(wallet->m_context, [wallet] {
        QMetaObject::invokeMethod(wallet, [wallet] {
            QSettings settings(GetDataFile("app", "wallets.ini"), QSettings::IniFormat);
            wallet->m_index = settings.beginReadArray("wallets");
            settings.endArray();
            settings.beginWriteArray("wallets", wallet->m_index + 1);
            settings.setArrayIndex(wallet->m_index);
            settings.setValue("proxy", wallet->m_proxy);
            settings.setValue("use_tor", wallet->m_use_tor);
            settings.setValue("network", wallet->m_network->id());
            settings.setValue("pin_data", wallet->m_pin_data);
            settings.setValue("name", wallet->m_name);
            settings.setValue("login_attempts_remaining", wallet->m_login_attempts_remaining);
            settings.endArray();
        });
    });
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
    QSet<QString> names;
    for (Wallet* wallet : m_wallets) {
        if (wallet->network() == network) names.insert(wallet->name());
    }
    int n = 0;
    QString name = QString("My %1 Wallet").arg(network->name());
    while (names.contains(name)) {
        name = QString("My %1 Wallet %2").arg(network->name()).arg(++n);
    }
    return name;
}

Wallet* WalletManager::signup(const QString& proxy, bool use_tor, Network* network, const QString& name, const QStringList& mnemonic, const QByteArray& pin)
{
    Q_ASSERT(mnemonic.size() == 24 || mnemonic.size() == 27);
    Wallet* wallet = new Wallet(this);
    wallet->m_proxy = proxy;
    wallet->m_use_tor = use_tor;
    wallet->m_network = network;
    wallet->m_name = name;
    wallet->connect(proxy, use_tor);
    wallet->signup(mnemonic, pin);
    m_wallets.append(wallet);
    emit walletsChanged();
    return wallet;
}

QStringList WalletManager::generateMnemonic() const
{
    char* mnemonic;
    int err = GA_generate_mnemonic(&mnemonic);
    Q_ASSERT(err == GA_OK);
    auto result = QString(mnemonic).split(' ');
    GA_destroy_string(mnemonic);
    return result;
}

QJsonObject WalletManager::parseUrl(const QString &url)
{
    QJsonObject r;
    QUrl res(url);
    QUrlQuery q(res);

    r.insert("address", res.path());
    r.insert("amount", q.queryItemValue("amount"));

    return r;
}
