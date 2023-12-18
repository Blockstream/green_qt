#ifndef GREEN_OUTPUTLISTMODELFILTER_H
#define GREEN_OUTPUTLISTMODELFILTER_H

#include "green.h"

#include <QSortFilterProxyModel>
#include <QtQml>

class OutputListModel;

class OutputListModelFilter : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(OutputListModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    QML_ELEMENT
public:
    OutputListModelFilter(QObject* parent = nullptr);
    OutputListModel* model() const { return m_model; }
    void setModel(OutputListModel* model);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;
    QString filter() { return m_filter; }
    void setFilter(const QString& filter);
signals:
    void modelChanged();
    void assetChanged();
    void filterChanged();
private:
    OutputListModel* m_model{nullptr};
    Asset* m_asset{nullptr};
    QString m_filter;
};

#endif // GREEN_OUTPUTLISTMODELFILTER_H
