#include "ga.h"
#include "json.h"
#include "walletmanager.h"

#include <QDebug>
#include <QSettings>

WalletManager::WalletManager(QObject *parent) : QObject(parent)
{
    GA_json* config;
    GA_convert_string_to_json("{}", &config);
    GA_init(config);
    GA_destroy_json(config);

    QSettings settings;

    int count = settings.beginReadArray("wallets");

    for (int index = 0; index < count; ++index) {
        settings.setArrayIndex(index);

        auto pin_data = settings.value("pin_data").toByteArray();
        auto name = settings.value("name").toString();
        auto network = settings.value("network", "testnet").toString();
        int login_attempts_remaining = settings.value("login_attempts_remaining").toInt();

        Wallet* wallet = new Wallet(this);
        wallet->m_index = index;
        wallet->m_pin_data = pin_data;
        wallet->m_name = name;
        wallet->m_network = network;
        wallet->m_login_attempts_remaining = login_attempts_remaining;

        m_wallets.append(wallet);
    }

    settings.endArray();

    /*
    if (settings.contains("wallet/pin_data")) {
        qDebug("DEFAULT WALLET");
        Wallet* wallet = new Wallet(this);
        qDebug() << settings.value("wallet/pin_data").toByteArray();
        wallet->m_pin_data = settings.value("wallet/pin_data").toByteArray();
        wallet->m_name = settings.value("wallet/name", "DEFAULT").toString();
        m_wallets.append(wallet);
    }
    */
    // return settings.value("wallet/pin_data").toByteArray();
}

//static int count(void *d) { return static_cast<QVector<Wallet*>*>(d)->size(); }
//static int at(void *d, int index) { return static_cast<QVector<Wallet*>*>(d)->size(); }

QQmlListProperty<Wallet> WalletManager::wallets()
{
    return QQmlListProperty<Wallet>(this, &m_wallets,
        [](QQmlListProperty<Wallet>* property) { return static_cast<QVector<Wallet*>*>(property->data)->size(); },
    [](QQmlListProperty<Wallet>* property, int index) { return static_cast<QVector<Wallet*>*>(property->data)->at(index); });
}

Wallet* WalletManager::signup(const QString& network, const QString& name, const QStringList& mnemonic, const QByteArray& pin)
{
    Wallet* wallet = new Wallet(this);
    wallet->m_network = network;
    wallet->m_name = name;
    wallet->connect();
    wallet->signup(mnemonic, pin);
    m_wallets.append(wallet);
    emit walletsChanged();
    return wallet;
}

QJsonObject WalletManager::networks()
{
    GA_json* output;
    int err = GA_get_networks(&output);
    Q_ASSERT(err == GA_OK);
    auto networks = Json::toObject(output);
    GA_destroy_json(output);
    return networks;
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
