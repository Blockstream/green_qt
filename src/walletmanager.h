#ifndef WALLETMANAGER_H
#define WALLETMANAGER_H

#include <QJsonObject>
#include <QObject>
#include <QQmlListProperty>
#include <QVector>

#include "wallet.h"

class Network;

class WalletManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<Wallet> wallets READ wallets NOTIFY walletsChanged)

public:
    explicit WalletManager(QObject *parent = nullptr);

    QQmlListProperty<Wallet> wallets();

signals:
    void walletsChanged();

public slots:
    QStringList generateMnemonic() const;
    QJsonObject parseUrl(const QString &url);
    Wallet* signup(const QString& proxy, bool use_tor, Network* network, const QString& name, const QStringList &mnemonic, const QString& password, const QByteArray& pin);
    QJsonObject networks();

private:
    QVector<Wallet*> m_wallets;
};

#endif // WALLETMANAGER_H
