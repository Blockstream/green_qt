#ifndef GREEN_ASSET_H
#define GREEN_ASSET_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QString>

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

class AssetManager : public QObject
{
    Q_OBJECT
public:
    explicit AssetManager();
    virtual ~AssetManager();

    static AssetManager* instance();

    static AssetManager* create(QQmlEngine*, QJSEngine*);

    QStandardItemModel* model() const { return m_model; }

    Q_INVOKABLE Asset* assetWithId(const QString& deployment, const QString& id);

private:
    QMap<QPair<QString, QString>, Asset*> m_assets;
    QStandardItemModel* const m_model;
};

class AssetsModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(int minWeight READ minWeight WRITE setMinWeight NOTIFY minWeightChanged)
    Q_PROPERTY(bool showLightning READ showLightning WRITE setShowLightning NOTIFY showLightningChanged)
    QML_ELEMENT
public:
    AssetsModel(QObject* parent = nullptr);
    QString filter() const { return m_filter; }
    void setFilter(const QString& filter);
    Context* context() const { return m_context; }
    void setContext(Context* context);
    int minWeight() const { return m_min_weight; }
    void setMinWeight(int min_weight);
    bool showLightning() const { return m_show_lightning; }
    void setShowLightning(bool show_lightning);
signals:
    void filterChanged();
    void contextChanged();
    void minWeightChanged();
    void showLightningChanged();
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;
private:
    QString m_filter;
    Context* m_context{nullptr};
    int m_min_weight{0};
    bool m_show_lightning{false};
};

#endif // GREEN_ASSET_H
