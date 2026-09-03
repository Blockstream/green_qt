#include "outputlistmodelfilter.h"

#include "output.h"
#include "outputlistmodel.h"

OutputListModelFilter::OutputListModelFilter(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    this->sort(0, Qt::AscendingOrder);
}

void OutputListModelFilter::setModel(OutputListModel* model)
{
    m_model = model;
    setSourceModel(model);
    emit modelChanged();
}

void OutputListModelFilter::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
    invalidate();
}

void OutputListModelFilter::setExcludeLocked(bool exclude_locked)
{
    if (m_exclude_locked == exclude_locked) return;
    m_exclude_locked = exclude_locked;
    emit excludeLockedChanged();
    invalidate();
}

void OutputListModelFilter::setActiveFilters(const QStringList& active_filters)
{
    if (m_active_filters == active_filters) return;
    m_active_filters = active_filters;
    emit activeFiltersChanged();
    invalidate();
}

void OutputListModelFilter::setSortMode(SortMode sort_mode)
{
    if (m_sort_mode == sort_mode) return;
    m_sort_mode = sort_mode;
    emit sortModeChanged();
    invalidate();
}

Output* OutputListModelFilter::outputAt(int row) const
{
    if (row < 0 || row >= rowCount()) return nullptr;
    return index(row, 0).data(Qt::UserRole).value<Output*>();
}

bool OutputListModelFilter::matchesActiveFilter(const QString& filter, Output* output) const
{
    if (filter == "dust") return output->dust();
    if (filter == "expired_2fa") return output->expired();
    if (filter == "legacy_recovery") return output->addressType() != "csv";
    return false;
}

bool OutputListModelFilter::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    auto output = m_model->index(source_row, 0, source_parent).data(Qt::UserRole).value<Output*>();
    if (!output) return false;
    if (m_asset && m_asset != output->asset()) return false;

    if (m_exclude_locked && output->locked()) return false;

    if (!m_active_filters.isEmpty()) {
        bool matches = false;
        for (const auto& filter : m_active_filters) {
            if (matchesActiveFilter(filter, output)) {
                matches = true;
                break;
            }
        }
        if (!matches) return false;
    }
    return true;
}

bool OutputListModelFilter::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    auto output_l = left.data(Qt::UserRole).value<Output*>();
    auto output_r = right.data(Qt::UserRole).value<Output*>();
    const auto output_l_height = output_l->data().value("block_height").toInteger();
    const auto output_r_height = output_r->data().value("block_height").toInteger();

    const auto output_l_amount = output_l->data().value("satoshi").toInteger();
    const auto output_r_amount = output_r->data().value("satoshi").toInteger();
    if (m_sort_mode == AmountDescending && output_l_amount != output_r_amount) {
        return output_l_amount > output_r_amount;
    }
    if (m_sort_mode == AmountAscending && output_l_amount != output_r_amount) {
        return output_l_amount < output_r_amount;
    }
    if (m_sort_mode == Newest || m_sort_mode == Oldest) {
        const bool output_l_unconfirmed = output_l_height == 0;
        const bool output_r_unconfirmed = output_r_height == 0;
        if (output_l_unconfirmed != output_r_unconfirmed) {
            return m_sort_mode == Newest ? output_l_unconfirmed : !output_l_unconfirmed;
        }
        if (output_l_height != output_r_height) {
            return m_sort_mode == Newest
                ? output_l_height > output_r_height
                : output_l_height < output_r_height;
        }
    }

    const auto output_l_outpoint = output_l->data().value("txhash").toString()
        + ':' + QString::number(output_l->data().value("pt_idx").toInt()).rightJustified(10, '0');
    const auto output_r_outpoint = output_r->data().value("txhash").toString()
        + ':' + QString::number(output_r->data().value("pt_idx").toInt()).rightJustified(10, '0');
    return output_l_outpoint < output_r_outpoint;
}
