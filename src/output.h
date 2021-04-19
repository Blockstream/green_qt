#ifndef GREEN_OUTPUT_H
#define GREEN_OUTPUT_H

#include <QtQml>
#include <QObject>
#include <QJsonObject>

QT_FORWARD_DECLARE_CLASS(Account)

class Output : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Output is instanced by Account.")
public:
    explicit Output(Account* account);
    virtual ~Output();
    Account* account() const { return m_account; }
    QJsonObject data() const { return m_data; }
    void updateFromData(const QJsonObject& data);
signals:
    void dataChanged(const QJsonObject& data);
public:
    Account* const m_account;
    QJsonObject m_data;
};

#endif // GREEN_OUTPUT_H
