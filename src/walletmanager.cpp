#include "ga.h"
#include "json.h"
#include "network.h"
#include "util.h"
#include "walletmanager.h"

#include <QDebug>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>

WalletManager::WalletManager(QObject *parent) : QObject(parent)
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

Wallet* WalletManager::createWallet()
{
    return new Wallet(this);
}

void WalletManager::insertWallet(Wallet* wallet)
{
    m_wallets.append(wallet);
    emit walletsChanged();
}

QQmlListProperty<Wallet> WalletManager::wallets()
{
    return QQmlListProperty<Wallet>(this, &m_wallets,
        [](QQmlListProperty<Wallet>* property) { return static_cast<QVector<Wallet*>*>(property->data)->size(); },
    [](QQmlListProperty<Wallet>* property, int index) { return static_cast<QVector<Wallet*>*>(property->data)->at(index); });
}

Wallet* WalletManager::signup(const QString& proxy, bool use_tor, Network* network, const QString& name, const QStringList& mnemonic, const QByteArray& pin)
{
    Q_ASSERT(mnemonic.size() == 24 || mnemonic.size() == 27);
    Wallet* wallet = new Wallet(this);
    wallet->m_proxy = proxy;
    wallet->m_use_tor = use_tor;
    wallet->m_network = network;
    wallet->m_name = name;
    wallet->connect();
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

#include <QUrl>
#include <QUrlQuery>
QJsonObject WalletManager::parseUrl(const QString &url)
{
    QJsonObject r;
    QUrl res(url);
    qDebug() << "SCHEMA" << res.scheme();
    qDebug() << "PATH" << res.path();
    qDebug() << "QUERY" << res.query();
    QUrlQuery q(res);
    qDebug() << "QUERY" << q.queryItemValue("amount");
    qDebug() << "LABEL" << q.queryItemValue("label");

    r.insert("address", res.path());
    r.insert("amount", q.queryItemValue("amount"));

    return r;
}
