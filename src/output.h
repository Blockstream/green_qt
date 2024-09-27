#ifndef GREEN_OUTPUT_H
#define GREEN_OUTPUT_H

#include <QJsonObject>
#include <QQmlEngine>
#include <QObject>

class Account;
class Asset;
class Context;
class Session;
class Transaction;

class Output : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(Asset* asset READ asset NOTIFY assetChanged)
    Q_PROPERTY(QString address READ address NOTIFY addressChanged)
    Q_PROPERTY(bool dust READ dust NOTIFY dustChanged)
    Q_PROPERTY(bool locked READ locked NOTIFY lockedChanged)
    Q_PROPERTY(bool confidential READ confidential NOTIFY confidentialChanged)
    Q_PROPERTY(bool unconfirmed READ unconfirmed NOTIFY unconfirmedChanged)
    Q_PROPERTY(bool canBeLocked READ canBeLocked NOTIFY canBeLockedChanged)
    Q_PROPERTY(QString addressType READ addressType NOTIFY addressTypeChanged)
    Q_PROPERTY(bool expired READ expired NOTIFY expiredChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Output is instanced by Account.")
public:
    explicit Output(const QJsonObject& data, Account* account);
    Account* account() const { return m_account; }
    Session* session() const;
    Asset* asset() const { return m_asset; }
    QString address() const { return m_address; }
    void setAddress(const QString& address);
    QJsonObject data() const { return m_data; }
    void updateFromData(const QJsonObject& data);
    void update();
    bool dust() const { return m_dust; }
    bool locked() const { return m_locked; }
    bool confidential() const { return m_confidential; }
    bool unconfirmed() const { return m_unconfirmed; }
    bool canBeLocked() const { return m_can_be_locked; }
    QString addressType() const { return m_address_type; }
    bool expired() const { return m_expired; }
    void setExpired(bool expired);
    void setSpendingTransaction(Transaction* transaction);
signals:
    void dataChanged();
    void assetChanged();
    void addressChanged();
    void dustChanged();
    void lockedChanged();
    void confidentialChanged();
    void unconfirmedChanged();
    void selectedChanged();
    void canBeLockedChanged();
    void addressTypeChanged();
    void expiredChanged();
private slots:
    void updateExpired();
    void updateNotifications();
private:
    void setDust(bool dust);
    void setLocked(bool locked);
    void setCanBeLocked(bool canBeLocked);
    void setConfidential(bool confidential);
    void setUnconfirmed(bool unconfirmed);
    void setAddressType(const QString& address_type);
public:
    Account* const m_account;
    Asset* m_asset{nullptr};
    QString m_address;
    QJsonObject m_data;
    bool m_dust{false};
    bool m_locked{false};
    bool m_confidential{false};
    bool m_unconfirmed{false};
    bool m_can_be_locked{false};
    QString m_address_type;
    bool m_expired{false};
    Transaction* m_spending_transaction{nullptr};
};

#endif // GREEN_OUTPUT_H
