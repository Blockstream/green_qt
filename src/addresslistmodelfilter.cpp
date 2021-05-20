#include "address.h"
#include "addresslistmodel.h"
#include "addresslistmodelfilter.h"

AddressListModelFilter::AddressListModelFilter(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}

void AddressListModelFilter::setModel(AddressListModel *model)
{
    m_model = model;
    if (model) setSourceModel(model);
    emit modelChanged(model);
}

bool AddressListModelFilter::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    if (m_filter.isEmpty()) return true;
    auto address = m_model->index(source_row, 0, source_parent).data(AddressListModel::AddressRole).value<Address*>();
    if (address->data()["address"].toString().contains(m_filter)) return true;
    return false;
}

void AddressListModelFilter::setFilter(const QString& filter)
{
    if (m_filter == filter) return;
    m_filter = filter;
    emit filterChanged(m_filter);
    invalidateFilter();
}
