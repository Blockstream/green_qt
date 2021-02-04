#ifndef GREEN_NETWORK_H
#define GREEN_NETWORK_H

#include <QtQml>
#include <QJsonObject>
#include <QObject>

class Network : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(bool liquid READ isLiquid CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("Network is instanced by NetworkManager.")
public:
    Network(const QJsonObject& data, QObject* parent = nullptr);

    QJsonObject data() const { return m_data; }
    QString id() const { return m_id; }
    QString name() const { return m_name; }
    QString explorerUrl() const;
    bool isLiquid() const;

    void openTransactionInExplorer(const QString& hash);

private:
    const QJsonObject m_data;
    QString m_id;
    QString m_name;
};

#endif // GREEN_NETWORK_H
