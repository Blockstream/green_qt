#ifndef GREEN_ADDRESS_H
#define GREEN_ADDRESS_H

#include <QJsonObject>
#include <QObject>
#include <QtQml>

class Account;

class Address : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(QString type READ type NOTIFY dataChanged)
    Q_PROPERTY(QString address READ address NOTIFY dataChanged)
    Q_PROPERTY(int pointer READ pointer NOTIFY dataChanged)
    Q_PROPERTY(bool verified READ verified NOTIFY verifiedChanged)
    Q_PROPERTY(QUrl url READ url NOTIFY dataChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Address is instanced by Account.")
public:
    explicit Address(Account* account);
    Account* account() const { return m_account; }
    QJsonObject data() const { return m_data; }
    QString type() const { return m_type; }
    QString address() const { return m_address; }
    int pointer() const { return m_pointer; }
    void updateFromData(const QJsonObject& data);
    bool verified() const { return m_verified; }
    void setVerified(bool verified);
    QUrl url() const;
signals:
    void dataChanged();
    void verifiedChanged();
public:
    Account* const m_account;
    QJsonObject m_data;
    QString m_type;
    QString m_address;
    int m_pointer{0};
    bool m_verified{false};
};

#endif // GREEN_ADDRESS_H
