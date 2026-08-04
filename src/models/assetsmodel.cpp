#include "asset.h"
#include "assetmanager.h"
#include "assetsmodel.h"
#include "context.h"
#include "device.h"
#include "network.h"
#include "networkmanager.h"
#include "wallet.h"

AssetsModel::AssetsModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setSourceModel(AssetManager::instance()->model());
    setDynamicSortFilter(true);
    sort(0); // NOLINT(build/include_what_you_use)
}

void AssetsModel::setFilter(const QString& filter)
{
    if (m_filter == filter) return;
    beginFilterChange();
    m_filter = filter;
    emit filterChanged();
    endFilterChange(Direction::Rows);
}

void AssetsModel::setContext(Context* context)
{
    if (m_context == context) return;
    beginFilterChange();
    m_context = context;
    emit contextChanged();
    endFilterChange(Direction::Rows);
}

void AssetsModel::setMinWeight(int min_weight)
{
    if (m_min_weight == min_weight) return;
    beginFilterChange();
    m_min_weight = min_weight;
    emit minWeightChanged();
    endFilterChange(Direction::Rows);
}

void AssetsModel::setShowAmp(bool show_amp)
{
    if (m_show_amp == show_amp) return;
    beginFilterChange();
    m_show_amp = show_amp;
    emit showAmpChanged();
    endFilterChange(Direction::Rows);
}

void AssetsModel::setShowLightning(bool show_lightning)
{
    if (m_show_lightning == show_lightning) return;
    beginFilterChange();
    m_show_lightning = show_lightning;
    emit showLightningChanged();
    endFilterChange(Direction::Rows);
}

bool AssetsModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    const auto index = sourceModel()->index(source_row, 0, source_parent);
    const auto asset = index.data(Qt::UserRole + 1).value<Asset*>();

    if (asset->isAmp() && !m_show_amp) return false;

    if (asset->isLightning() && (!m_show_lightning || !m_context || !m_context->lightningEnabled())) {
        return false;
    }

    if (asset->weight() < m_min_weight) return false;

    if (m_filter.isEmpty()) {
        if (asset->weight() == 0 && (!asset->hasData() || !asset->hasIcon())) return false;
    } else {
        if (!asset->name().contains(m_filter, Qt::CaseInsensitive) &&
            !asset->ticker().contains(m_filter, Qt::CaseInsensitive)) return false;
    }

    if (m_context) {
        if (!m_context->deployment().isEmpty()) {
            if (asset->deployment() != m_context->deployment()) return false;
        }

        if (const auto device = m_context->device()) {
            bool supports = false;
            for (auto network : NetworkManager::instance()->networks()) {
                if (network->key() == asset->networkKey()) {
                    if (device->supportsNetwork(network)) {
                        supports = true;
                        break;
                    }
                }
            }
            if (!supports) return false;
        }

        const auto watchonly_data = qobject_cast<WatchonlyData*>(m_context->wallet()->login());
        if (watchonly_data && watchonly_data->network()->key() != asset->networkKey()) {
            return false;
        }
    }

    return true;
}

bool AssetsModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    const auto asset_left = left.data(Qt::UserRole + 1).value<Asset*>();
    const auto asset_right = right.data(Qt::UserRole + 1).value<Asset*>();

    if (asset_left->weight() > asset_right->weight()) return true;
    if (asset_left->weight() < asset_right->weight()) return false;

    if (asset_left->weight() == 0) {
        if (asset_left->hasIcon() && !asset_right->hasIcon()) return true;
        if (!asset_left->hasIcon() && asset_right->hasIcon()) return false;

        if (asset_left->hasData() && !asset_right->hasData()) return true;
        if (!asset_left->hasData() && asset_right->hasData()) return false;
    }
    return QString::localeAwareCompare(asset_left->name(), asset_right->name()) < 0;
}
