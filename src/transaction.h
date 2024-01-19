#ifndef GREEN_TRANSACTION_H
#define GREEN_TRANSACTION_H

#include <QJsonObject>
#include <QObject>
#include <QtQml>

class Account;
class Asset;
class Transaction;
class Context;

Q_MOC_INCLUDE("account.h")
Q_MOC_INCLUDE("asset.h")

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
    Q_PROPERTY(Type type READ type NOTIFY typeChanged)
    Q_PROPERTY(QQmlListProperty<TransactionAmount> amounts READ amounts NOTIFY amountsChanged)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(QString memo READ memo NOTIFY memoChanged)
    Q_PROPERTY(SPVStatus spv READ spvStatus NOTIFY spvStatusChanged)
    Q_PROPERTY(QJsonObject destination READ destination NOTIFY dataChanged)
    Q_PROPERTY(QUrl url READ url NOTIFY dataChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Transaction is instanced by Wallet.")
public:
    enum class Type {
        Unknown,
        Incoming,
        Outgoing,
        Redeposit,
        Mixed,
    };
    Q_ENUM(Type)
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

    Type type() const { return m_type; }
    QString hash() const { return m_data.value("txhash").toString(); }
    QString memo() const { return m_memo; }
    SPVStatus spvStatus() const { return m_spv_status; }

    bool isUnconfirmed() const;

    Context* context() const;
    Account* account() const;

    QQmlListProperty<TransactionAmount> amounts();

    QJsonObject data() const;

    QJsonObject destination() const;
    void updateFromData(const QJsonObject& data);

    QUrl url() const;

public slots:
    void openInExplorer() const;
    QString link();
    QString unblindedLink();
    void updateMemo(const QString& memo);

signals:
    void typeChanged(Transaction::Type type);
    void amountsChanged();
    void dataChanged(const QJsonObject& data);
    void memoChanged(const QString& memo);
    void spvStatusChanged(Transaction::SPVStatus spv_status);

private:
    void setType(Type type);
    void setMemo(const QString& memo);
    void setSpvStatus(SPVStatus spv_status);
public:
    Account* const m_account;
    Type m_type{Type::Unknown};
    QList<TransactionAmount*> m_amounts;
    QJsonObject m_data;
    QString m_memo;
    SPVStatus m_spv_status{SPVStatus::Disabled};
};

#endif // GREEN_TRANSACTION_H
