#ifndef GREEN_ADDRESS_H
#define GREEN_ADDRESS_H

#include <QtQml>
#include <QObject>
#include <QJsonObject>

QT_FORWARD_DECLARE_CLASS(Account)

class Address : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Address is instanced by Account.")
public:
    explicit Address(Account* account);
    virtual ~Address();
    Account* account() const { return m_account; }
    QJsonObject data() const { return m_data; }
    void updateFromData(const QJsonObject& data);
signals:
    void dataChanged(const QJsonObject& data);
public:
    Account* const m_account;
    QJsonObject m_data;
};

#endif // GREEN_ADDRESS_H
