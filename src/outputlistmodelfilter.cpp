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

    if (m_filter=="all") return true;
    else if (m_filter=="csv") return output->addressType()=="csv";
    else if (m_filter=="p2wsh") return output->addressType()=="p2wsh";
    else if (m_filter=="dust") return output->dust();
    else if (m_filter=="locked") return output->locked();
    else if (m_filter=="not confidential") return output->data()["confidential"].toBool()==false;

    return false;
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
