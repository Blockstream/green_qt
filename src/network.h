#ifndef GREEN_NETWORK_H
#define GREEN_NETWORK_H

#include <QtQml>
#include <QJsonObject>
#include <QObject>

class Network : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString key READ key CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QJsonObject data READ data CONSTANT)
    Q_PROPERTY(bool liquid READ isLiquid CONSTANT)
    Q_PROPERTY(bool electrum READ isElectrum CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("Network is instanced by NetworkManager.")
public:
    Network(const QJsonObject& data, QObject* parent = nullptr);

    QJsonObject data() const { return m_data; }
    QString key() const { return m_key; }
    QString id() const { return m_id; }
    QString name() const { return m_name; }
    QString policyAsset() const;
    QString explorerUrl() const;
    bool isLiquid() const { return m_liquid; }
    bool isElectrum() const { return m_electrum; }

    void openTransactionInExplorer(const QString& hash);

private:
    const QJsonObject m_data;
    const QString m_id;
    const QString m_key;
    const QString m_name;
    const bool m_liquid;
    const bool m_electrum;
    const QString m_policy_asset;
};

#endif // GREEN_NETWORK_H
