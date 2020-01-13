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

    Q_INVOKABLE Wallet* createWallet();

    Q_INVOKABLE void insertWallet(Wallet* wallet);

    QQmlListProperty<Wallet> wallets();

signals:
    void walletsChanged();

public slots:
    QStringList generateMnemonic() const;
    QJsonObject parseUrl(const QString &url);
    Wallet* signup(const QString& proxy, bool use_tor, Network* network, const QString& name, const QStringList &mnemonic, const QByteArray& pin);

private:
    QVector<Wallet*> m_wallets;
};

#endif // WALLETMANAGER_H
