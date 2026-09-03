#ifndef GREEN_OUTPUTLISTMODELFILTER_H
#define GREEN_OUTPUTLISTMODELFILTER_H

#include "green.h"

#include <QSortFilterProxyModel>
#include <QtQml>

class OutputListModel;
class Output;

class OutputListModelFilter : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(OutputListModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(bool excludeLocked READ excludeLocked WRITE setExcludeLocked NOTIFY excludeLockedChanged)
    Q_PROPERTY(QStringList activeFilters READ activeFilters WRITE setActiveFilters NOTIFY activeFiltersChanged)
    Q_PROPERTY(SortMode sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    QML_ELEMENT
public:
    enum SortMode {
        AmountDescending,
        AmountAscending,
        Newest,
        Oldest,
    };
    Q_ENUM(SortMode)

    OutputListModelFilter(QObject* parent = nullptr);
    OutputListModel* model() const { return m_model; }
    void setModel(OutputListModel* model);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;
    bool excludeLocked() const { return m_exclude_locked; }
    void setExcludeLocked(bool exclude_locked);
    QStringList activeFilters() const { return m_active_filters; }
    void setActiveFilters(const QStringList& active_filters);
    SortMode sortMode() const { return m_sort_mode; }
    void setSortMode(SortMode sort_mode);
    Q_INVOKABLE Output* outputAt(int row) const;
signals:
    void modelChanged();
    void assetChanged();
    void excludeLockedChanged();
    void activeFiltersChanged();
    void sortModeChanged();
private:
    bool matchesActiveFilter(const QString& filter, Output* output) const;
    OutputListModel* m_model{nullptr};
    Asset* m_asset{nullptr};
    bool m_exclude_locked{false};
    QStringList m_active_filters;
    SortMode m_sort_mode{AmountDescending};
};

#endif // GREEN_OUTPUTLISTMODELFILTER_H
