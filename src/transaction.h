#ifndef GREEN_TRANSACTION_H
#define GREEN_TRANSACTION_H

#include <QtQml>
#include <QObject>
#include <QJsonObject>

class Account;
class Asset;
class Transaction;

class TransactionAmount : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Transaction* transaction READ transaction CONSTANT)
    Q_PROPERTY(Asset* asset READ asset CONSTANT)
    Q_PROPERTY(qint64 amount READ amount CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("TransactionAmount is instanced by Transaction.")
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
    Q_PROPERTY(QString memo READ memo NOTIFY memoChanged)
    Q_PROPERTY(SPVStatus spv READ spvStatus NOTIFY spvStatusChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Transaction is instanced by Wallet.")
public:
    enum class SPVStatus {
        Disabled,
        Unconfirmed,
        InProgress,
        Verified,
        NotVerified,
        NotLongest,
    };
    Q_ENUM(SPVStatus)

    explicit Transaction(Account* account);
    virtual ~Transaction();

    QString hash() const { return m_data.value("txhash").toString(); }
    QString memo() const { return m_memo; }
    SPVStatus spvStatus() const { return m_spv_status; }

    bool isUnconfirmed() const;

    Account* account() const;

    QQmlListProperty<TransactionAmount> amounts();

    QJsonObject data() const;

    void updateFromData(const QJsonObject& data);

public slots:
    void openInExplorer() const;
    QString link() const;
    QString unblindedLink() const;
    void updateMemo(const QString& memo);

signals:
    void amountsChanged();
    void dataChanged(const QJsonObject& data);
    void memoChanged(const QString& memo);
    void spvStatusChanged(SPVStatus spv_status);

private:
    void setMemo(const QString& memo);
    void setSpvStatus(SPVStatus spv_status);
public:
    Account* const m_account;
    QList<TransactionAmount*> m_amounts;
    QJsonObject m_data;
    QString m_memo;
    SPVStatus m_spv_status{SPVStatus::Disabled};
};

#endif // GREEN_TRANSACTION_H
