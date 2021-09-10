#ifndef GREEN_OUTPUT_H
#define GREEN_OUTPUT_H

#include <QtQml>
#include <QObject>
#include <QJsonObject>

QT_FORWARD_DECLARE_CLASS(Account)
QT_FORWARD_DECLARE_CLASS(Asset)

class Output : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(Asset* asset READ asset NOTIFY assetChanged)
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
    Asset* asset() const { return m_asset; }
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
signals:
    void dataChanged(const QJsonObject& data);
    void assetChanged(const Asset* asset);
    void dustChanged(bool dust);
    void lockedChanged(bool locked);
    void confidentialChanged(bool confidential);
    void unconfirmedChanged(bool unconfirmed);
    void selectedChanged(bool selected);
    void canBeLockedChanged(bool canBeLocked);
    void addressTypeChanged(const QString& address_type);
    void expiredChanged(bool expired);
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
    QJsonObject m_data;
    bool m_dust{false};
    bool m_locked{false};
    bool m_confidential{false};
    bool m_unconfirmed{false};
    bool m_can_be_locked{false};
    QString m_address_type;
    bool m_expired{false};
};

#endif // GREEN_OUTPUT_H
