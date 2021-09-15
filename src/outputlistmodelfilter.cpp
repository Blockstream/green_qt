#include "output.h"
#include "outputlistmodel.h"
#include "outputlistmodelfilter.h"
#include "network.h"

OutputListModelFilter::OutputListModelFilter(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    this->sort(0, Qt::DescendingOrder);
}

void OutputListModelFilter::setModel(OutputListModel *model)
{
    m_model = model;
    setSourceModel(model);
    emit modelChanged(model);
}

bool OutputListModelFilter::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    auto output = m_model->index(source_row, 0, source_parent).data(Qt::UserRole).value<Output*>();

    for (auto filter : m_filter.split(' ', Qt::SkipEmptyParts)) {
        bool invert = filter.startsWith('!');
        if (invert) filter = filter.mid(1);
        bool result = true;
        if (filter == "csv") result = output->addressType() == "csv";
        if (filter == "p2wsh") result = output->addressType() == "p2wsh";
        if (filter == "dust") result = output->dust();
        if (filter == "locked") result = output->locked();
        if (filter == "not_confidential") result = !output->confidential();
        if (filter == "expired") result = output->expired();
        if (invert) result = !result;
        if (!result) return false;
    }
    return true;
}

bool OutputListModelFilter::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    double output_l_height = left.data(Qt::UserRole).value<Output*>()->data()["block_height"].toDouble();
    double output_r_height = right.data(Qt::UserRole).value<Output*>()->data()["block_height"].toDouble();

    // exception to bring unconfirmed coins to top of the list
    if (output_l_height==0) return true;
    if (output_r_height==0) return true;

    if (output_l_height<output_r_height) return true;
    if (output_l_height>output_r_height) return false;

    return QSortFilterProxyModel::lessThan(left, right);
}

QString OutputListModelFilter::filter()
{
    return m_filter;
}

void OutputListModelFilter::setFilter(const QString &filter)
{
    m_filter = filter;
    invalidate();
    emit filterChanged(filter);
}
