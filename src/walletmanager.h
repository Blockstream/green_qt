#ifndef WALLETMANAGER_H
#define WALLETMANAGER_H

#include <QObject>
#include <QQmlListProperty>
#include <QVector>

#include "wallet.h"

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
    QJsonObject parseUrl(const QString &url);

private:
    QVector<Wallet*> m_wallets;
};

#endif // WALLETMANAGER_H
