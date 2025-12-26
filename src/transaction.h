#ifndef GREEN_TRANSACTION_H
#define GREEN_TRANSACTION_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QtQml>

Q_MOC_INCLUDE("account.h")
Q_MOC_INCLUDE("asset.h")
Q_MOC_INCLUDE("payment.h")

class Transaction : public QObject
{
    Q_OBJECT
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

    explicit Transaction(const QString& hash, Account* account);
    virtual ~Transaction();

    Type type() const { return m_type; }
    QString hash() const { return m_hash; }
    QString memo() const { return m_memo; }

    bool isUnconfirmed() const;

    Context* context() const;
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
    Account* const m_account;
    QString const m_hash;
    Type m_type{Type::Unknown};
    QJsonObject m_data;
    QString m_memo;
    Payment* m_payment{nullptr};
};

#endif // GREEN_TRANSACTION_H
