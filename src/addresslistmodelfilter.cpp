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
    auto address = m_model->index(source_row, 0, source_parent).data(AddressListModel::AddressRole).value<Address*>();
    return filterRegExp().indexIn(address->data()["address"].toString()) >= 0;
}

void AddressListModelFilter::search(const QString &search)
{
    if (search.count()>0) setFilterRegExp(QRegExp(QString("(%1)").arg(search)));
    else setFilterRegExp(QRegExp(".*"));
}

void AddressListModelFilter::clear()
{
    setFilterRegExp(QRegExp(".*"));
}
