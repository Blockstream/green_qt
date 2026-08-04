#ifndef BLOCKSTREAM_ASSETSMODEL_H
#define BLOCKSTREAM_ASSETSMODEL_H

#include "green.h"

#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QString>

class AssetsModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(int minWeight READ minWeight WRITE setMinWeight NOTIFY minWeightChanged)
    Q_PROPERTY(bool showAmp READ showAmp WRITE setShowAmp NOTIFY showAmpChanged)
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
    bool showAmp() const { return m_show_amp; }
    void setShowAmp(bool show_amp);
    bool showLightning() const { return m_show_lightning; }
    void setShowLightning(bool show_lightning);
signals:
    void filterChanged();
    void contextChanged();
    void minWeightChanged();
    void showAmpChanged();
    void showLightningChanged();
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;
private:
    QString m_filter;
    Context* m_context{nullptr};
    int m_min_weight{0};
    bool m_show_amp{true};
    bool m_show_lightning{false};
};

#endif // BLOCKSTREAM_ASSETSMODEL_H
