#include "output.h"
#include "outputlistmodel.h"
#include "outputlistmodelfilter.h"

OutputListModelFilter::OutputListModelFilter(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    // "expired" << "locktime"
    m_tags << "csv" << "dust" << "frozen" << "not confidential";
}

void OutputListModelFilter::setModel(OutputListModel *model)
{
    m_model = model;
    if (model) setSourceModel(model);
    emit modelChanged(model);
}

bool OutputListModelFilter::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    auto output = m_model->index(source_row, 0, source_parent).data(Qt::UserRole).value<Output*>();

    if (m_filter=="") return true;
    else {
        if (m_filter=="csv") {
            return output->data()["address_type"].toString()=="csv";
        } else if (m_filter=="dust") {
            return output->data()["satoshi"].toDouble()<1092;
        } else if (m_filter=="frozen") {
            return output->data()["user_status"].toInt()==1;
        } else if (m_filter=="not confidential") {
            return output->data()["not confidential"].toBool()==false;
        }
    }

    return false;
}

bool OutputListModelFilter::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    double output_l_height = sourceModel()->data(left, Qt::UserRole).value<Output*>()->data()["satoshi"].toDouble();
    double output_r_height = sourceModel()->data(right, Qt::UserRole).value<Output*>()->data()["satoshi"].toDouble();

    if (output_l_height<=output_r_height) return true;
    else return false;
}

void OutputListModelFilter::filterBy(const QString &filter)
{
    m_filter = filter;
    invalidate();
}

void OutputListModelFilter::clear()
{
    m_filter = "";
    invalidate();
}

QStringList OutputListModelFilter::tags()
{
    return m_tags;
}
