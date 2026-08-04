#ifndef BLOCKSTREAM_ASSET_H
#define BLOCKSTREAM_ASSET_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QStandardItemModel>
#include <QString>

constexpr auto kLightningAssetId = "lnbtc";

class Asset : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString deployment READ deployment CONSTANT)
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString networkKey READ networkKey CONSTANT)
    Q_PROPERTY(QString icon READ icon NOTIFY iconChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool policy READ policy NOTIFY policyChanged)
    Q_PROPERTY(bool lightning READ isLightning CONSTANT)
    Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)
    Q_PROPERTY(bool amp READ isAmp NOTIFY isAmpChanged)
    Q_PROPERTY(int weight READ weight NOTIFY weightChanged)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(QString key READ key CONSTANT)
    Q_PROPERTY(QUrl url READ url CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("Asset is instanced by AssetManager")
public:
    explicit Asset(const QString& deployment, const QString& id, QObject* parent);

    QString deployment() const { return m_deployment; }

    QString networkKey() const { return m_network_key; }

    QString id() const { return m_id; }
    QStandardItem* item() const { return m_item; }

    QString name() const { return m_name; }
    void setName(const QString& name);

    QString ticker() const;
    bool hasIcon() const { return !m_icon.isEmpty(); }
    QString icon() const { return m_icon; }
    void setIcon(const QString& icon);

    bool isAmp() const { return m_is_amp; }
    void setIsAmp(bool is_amp);
    int weight() const { return m_weight; }
    void setWeight(int weight);

    bool policy() const { return m_policy; }
    void setPolicy(bool policy);

    bool isLightning() const;

    int precision() const;

    bool hasData() const { return !m_data.isEmpty(); }
    QJsonObject data() const { return m_data; }
    void setData(const QJsonObject& data);

    QString key() const { return m_key; }
    void setKey(const QString& key);

    QUrl url() const;

    Q_INVOKABLE QString formatAmount(qint64 amount, bool include_ticker, const QString& unit = {}) const;

signals:
    void nameChanged();
    void iconChanged();
    void policyChanged();
    void dataChanged();
    void isAmpChanged();
    void weightChanged();

private:
    QString const m_deployment;
    QString const m_id;
    QString const m_network_key;
    QStandardItem* const m_item;
    QString m_name;
    QString m_icon;
    bool m_policy{false};
    QJsonObject m_data;
    bool m_is_amp{false};
    int m_weight{0};
    QString m_key;
};

#endif // BLOCKSTREAM_ASSET_H
