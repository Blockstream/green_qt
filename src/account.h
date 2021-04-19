#ifndef GREEN_ACCOUNT_H
#define GREEN_ACCOUNT_H

#include "wallet.h"

#include <QtQml>
#include <QObject>

QT_FORWARD_DECLARE_CLASS(Address)
QT_FORWARD_DECLARE_CLASS(Output)
QT_FORWARD_DECLARE_CLASS(Balance)
QT_FORWARD_DECLARE_CLASS(Transaction)
QT_FORWARD_DECLARE_CLASS(Wallet)

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

    Wallet* wallet() const { return m_wallet; }
    int pointer() const { Q_ASSERT(m_pointer >= 0); return m_pointer; }
    bool isMainAccount() const;

    QString name() const;
    QJsonObject json() const;

    void update(const QJsonObject& json);

    void handleNotification(const QJsonObject& notification);

    qint64 balance() const;

    QQmlListProperty<Balance> balances();

    void updateBalance();
    Transaction *getOrCreateTransaction(const QJsonObject &data);
    Output *getOrCreateOutput(const QJsonObject &data);
    Address *getOrCreateAddress(const QJsonObject &data);
    Q_INVOKABLE Balance* getBalanceByAssetId(const QString &id) const;
    Q_INVOKABLE Transaction* getTransactionByTxHash(const QString &id) const;
signals:
    void walletChanged();
    void jsonChanged();
    void balanceChanged();
    void balancesChanged();
    void notificationHandled(const QJsonObject& notification);
public slots:
    void reload();
    void rename(QString name, bool active_focus);
private:
    Wallet* const m_wallet;
    int m_pointer{-1};
    QJsonObject m_json;
    QMap<QString, Transaction*> m_transactions_by_hash;
    QMap<QPair<QString, int>, Output*> m_outputs_by_hash;
    QMap<QString, Address*> m_address_by_hash;
    QList<Balance*> m_balances;
    QMap<QString, Balance*> m_balance_by_id;
    friend class Wallet;
};

class AccountActivity : public WalletActivity
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    QML_ELEMENT
public:
    AccountActivity(Account* account, QObject* parent);
    Account* account() const { return m_account; }
private:
    Connectable<Account> m_account;
};

class AccountGetTransactionsActivity : public AccountActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    AccountGetTransactionsActivity(Account* account, int first, int count, QObject* parent);
    void exec() override;
    QVector<Transaction*> transactions() const { return m_transactions; }
private:
    const int m_first;
    const int m_count;
    QVector<Transaction*> m_transactions;
};

class AccountGetUnspentOutputsActivity : public AccountActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    AccountGetUnspentOutputsActivity(Account* account, int m_num_confs, bool all_coins, QObject* parent);
    void exec() override;
    QVector<Output*> outputs() const { return m_outputs; }
private:
    const int m_num_confs;
    const bool m_all_coins;
    QVector<Output*> m_outputs;
};

#endif // GREEN_ACCOUNT_H
