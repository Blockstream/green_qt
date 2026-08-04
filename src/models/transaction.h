#ifndef BLOCKSTREAM_TRANSACTION_H
#define BLOCKSTREAM_TRANSACTION_H

#include "context.h"
#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QtQml>

Q_MOC_INCLUDE("account.h")
Q_MOC_INCLUDE("asset.h")
Q_MOC_INCLUDE("payment.h")
Q_MOC_INCLUDE("swap.h")

struct LightningPayment;

class ChainTransaction : public ContextTransaction
{
    Q_OBJECT
    Q_PROPERTY(Swap* swap READ swap NOTIFY swapChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ChainTransaction(const QString& id, Context* context);
    Swap* swap() const { return m_swap; }
    void setSwap(Swap* swap);
signals:
    void swapChanged();
private:
    Swap* m_swap{nullptr};
};

class AccountTransaction : public ContextTransaction
{
    Q_OBJECT
    Q_PROPERTY(ChainTransaction* chainTransaction READ chainTransaction CONSTANT)
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(Type type READ type NOTIFY typeChanged)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(QString memo READ memo NOTIFY memoChanged)
    Q_PROPERTY(QJsonObject destination READ destination NOTIFY dataChanged)
    Q_PROPERTY(QUrl url READ url NOTIFY dataChanged)
    Q_PROPERTY(Payment* payment READ payment NOTIFY paymentChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum class Type {
        Unknown,
        Incoming,
        Outgoing,
        Redeposit,
        Mixed,
        NotUnblindable,
    };
    Q_ENUM(Type)

    explicit AccountTransaction(ChainTransaction* chain_transaction, Account* account);
    virtual ~AccountTransaction();

    ChainTransaction* chainTransaction() const { return m_chain_transaction; }
    Type type() const { return m_type; }
    QString hash() const { return id(); }
    QString memo() const { return m_memo; }

    QDateTime timestamp() const override;

    bool isUnconfirmed() const;

    Account* account() const;

    QJsonObject data() const;

    QJsonObject destination() const;
    void updateFromData(const QJsonObject& data);

    QUrl url() const;

    bool hasAsset(Asset* asset) const;

    Payment* payment() const { return m_payment; }
    void setPayment(Payment* payment);

public slots:
    void openInExplorer() const;
    QString link();
    QString unblindedLink();
    void updateMemo(const QString& memo);

signals:
    void typeChanged();
    void amountsChanged();
    void dataChanged();
    void memoChanged();
    void paymentChanged();
private:
    void setType(Type type);
    void setMemo(const QString& memo);
private:
    ChainTransaction* const m_chain_transaction;
    Account* const m_account;
    Type m_type{Type::Unknown};
    QJsonObject m_data;
    QString m_memo;
    Payment* m_payment{nullptr};
};

class LightningTransaction : public ContextTransaction
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    explicit LightningTransaction(const QString& id, Context* context);

    QDateTime timestamp() const override;
    QJsonObject data() const { return m_data; }
    void updateFromPayment(const LightningPayment& payment);

signals:
    void dataChanged();

private:
    QJsonObject m_data;
};

#endif // BLOCKSTREAM_TRANSACTION_H
