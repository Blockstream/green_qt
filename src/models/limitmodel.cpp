#include "limitmodel.h"

LimitModel::LimitModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
}

void LimitModel::setSource(QAbstractItemModel* source)
{
    if (m_source == source) return;
    setSourceModel(nullptr);
    m_source = source;
    emit sourceChanged();
    setSourceModel(m_source);
}

void LimitModel::setLimit(int limit)
{
    if (m_limit == limit) return;
    m_limit = limit;
    emit limitChanged();
    invalidate();
}

bool LimitModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    return m_limit >= 0 && source_row < m_limit;
}
