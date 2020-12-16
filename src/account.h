#ifndef GREEN_ACCOUNT_H
#define GREEN_ACCOUNT_H

#include <QtQml>
#include <QObject>

class Balance;
class Transaction;
class Wallet;

class Account : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(bool mainAccount READ isMainAccount NOTIFY jsonChanged)
    Q_PROPERTY(QJsonObject json READ json NOTIFY jsonChanged)
    Q_PROPERTY(QString name READ name NOTIFY jsonChanged)
    Q_PROPERTY(qint64 balance READ balance NOTIFY balanceChanged)
    Q_PROPERTY(QQmlListProperty<Balance> balances READ balances NOTIFY balancesChanged)
    QML_ELEMENT
public:
    explicit Account(Wallet* wallet);

    Wallet* wallet() const;

    bool isMainAccount() const;

    QString name() const;
    QJsonObject json() const;

    void update(const QJsonObject& json);

    void handleNotification(const QJsonObject &notification);

    qint64 balance() const;

    QQmlListProperty<Balance> balances();

    void updateBalance();

signals:
    void walletChanged();
    void jsonChanged();
    void balanceChanged();

    void balancesChanged();
    void notificationHandled(const QJsonObject &notification);
public slots:
    void reload();

public:
    Wallet* const m_wallet;
    QMap<QString, Transaction*> m_transactions_by_hash;
    QList<Balance*> m_balances;
    QMap<QString, Balance*> m_balance_by_id;
    bool m_have_unconfirmed{false};
    QJsonObject m_json;
    int m_pointer;

    QJsonArray m_transactions_data;
    Transaction *getOrCreateTransaction(const QJsonObject &data);
};

#endif // GREEN_ACCOUNT_H
