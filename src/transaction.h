#ifndef GREEN_TRANSACTION_H
#define GREEN_TRANSACTION_H

#include <QObject>
#include <QJsonObject>
#include <QtQml>

class Account;
class Asset;
class Transaction;

class TransactionAmount : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Transaction* transaction READ transaction CONSTANT)
    Q_PROPERTY(Asset* asset READ asset CONSTANT)
    Q_PROPERTY(qint64 amount READ amount CONSTANT)

public:
    explicit TransactionAmount(Transaction* transaction, qint64 amount);
    explicit TransactionAmount(Transaction* transaction, Asset* asset, qint64 amount);
    virtual ~TransactionAmount();

    Transaction* transaction() const { return m_transaction; }

    Asset* asset() const { return m_asset; }

    qint64 amount() const { return m_amount; }

    Q_INVOKABLE QString formatAmount(bool include_ticker = true) const;

private:
    Transaction* const m_transaction;
    Asset* const m_asset;
    qint64 const m_amount;
};

class Transaction : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(QQmlListProperty<TransactionAmount> amounts READ amounts NOTIFY amountsChanged)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)

public:
    explicit Transaction(Account* account);
    virtual ~Transaction();

    bool isUnconfirmed() const;

    Account* account() const;

    QQmlListProperty<TransactionAmount> amounts();

    QJsonObject data() const;

    void updateFromData(const QJsonObject& data);

public slots:
    void openInExplorer() const;
    void updateMemo(const QString& memo);

signals:
    void amountsChanged();
    void dataChanged(const QJsonObject& data);

public:
    Account* const m_account;
    QList<TransactionAmount*> m_amounts;
    QJsonObject m_data;
};

#endif // GREEN_TRANSACTION_H
