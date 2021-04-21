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
    QML_ELEMENT
    QML_UNCREATABLE("Output is instanced by Account.")
public:
    explicit Output(Account* account);
    virtual ~Output();
    Account* account() const { return m_account; }
    Asset* asset() const { return m_asset; }
    QJsonObject data() const { return m_data; }
    void updateFromData(const QJsonObject& data);
    Q_INVOKABLE QString formatAmount(bool include_ticker = true) const;
signals:
    void dataChanged(const QJsonObject& data);
    void assetChanged(const Asset* asset);
public:
    Account* const m_account;
    Asset* m_asset = nullptr;
    QJsonObject m_data;
};

#endif // GREEN_OUTPUT_H
