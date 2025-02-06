#include "analytics.h"
#include "asset.h"
#include "context.h"
#include "device.h"
#include "network.h"
#include "networkmanager.h"

#include <QLocale>
#include <QtMath>

Asset::Asset(const QString& deployment, const QString& id, QObject* parent)
    : QObject(parent)
    , m_deployment(deployment)
    , m_id(id)
    , m_key(id)
    , m_item(new QStandardItem)
{
    m_item->setData(QVariant::fromValue(this));
}

void Asset::setNetworkKey(const QString& network_key)
{
    if (m_network_key == network_key) return;
    Q_ASSERT(m_network_key.isEmpty());
    m_network_key = network_key;
    emit networkKeyChanged();
}

void Asset::setIcon(const QString& icon)
{
    if (m_icon == icon) return;
    m_icon = icon;
    emit iconChanged();
}

void Asset::setName(const QString& name)
{
    if (m_name == name) return;
    Q_ASSERT(m_name.isEmpty());
    m_name = name;
    emit nameChanged();
}

QString Asset::ticker() const
{
    return m_data.value("ticker").toString();
}

void Asset::setIsAmp(bool is_amp)
{
    if (m_is_amp == is_amp) return;
    m_is_amp = is_amp;
    emit isAmpChanged();
}

void Asset::setWeight(int weight)
{
    if (m_weight == weight) return;
    m_weight = weight;
    emit weightChanged();
    m_item->setData(m_weight, Qt::UserRole + 2);
}

void Asset::setPolicy(bool policy)
{
    if (m_policy == policy) return;
    m_policy = policy;
    emit policyChanged();
}

int Asset::precision() const
{
    return data().value("precision").toInt(0);
}

void Asset::setData(const QJsonObject &data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();
    if (m_data.value("name") != "btc") {
        setName(m_data.value("name").toString());
    }
}

void Asset::setKey(const QString &key)
{
    m_key = key;
}

QUrl Asset::url() const
{
    const auto network = NetworkManager::instance()->networkWithServerType(m_deployment, m_network_key, "green");
    const auto tx_explorer_url = network->data().value("tx_explorer_url").toString();
    const auto asset_explorer_url = tx_explorer_url.sliced(0, tx_explorer_url.size() - 3) + "asset/";
    return { asset_explorer_url + m_id };
}

QString Asset::formatAmount(qint64 amount, bool include_ticker, const QString& unit) const
{
//    TODO format should be done from the account since the account holds the network
//    if (isLBTC()) {
//        return m_context->wallet()->formatAmount(amount, include_ticker, unit);
//    }

    auto precision = m_data.value("precision").toInt(0);
    auto str = QLocale::system().toString(static_cast<double>(amount) / qPow(10, precision), 'f', precision);

    if (include_ticker) {
        auto ticker = m_data.value("ticker").toString();
        if (!ticker.isEmpty()) str += " " + ticker;
    }

    return str;
}

static AssetManager* g_asset_manager{nullptr};

AssetManager::AssetManager()
    : m_model(new QStandardItemModel(this))
{
    Q_ASSERT(!g_asset_manager);
    g_asset_manager = this;

    m_model->setItemRoleNames({
        { Qt::UserRole + 1, "asset" },
        { Qt::UserRole + 2, "weight" },
    });

    connect(Analytics::instance(), &Analytics::remoteConfigChanged, this, [this] {
        auto liquid_assets = Analytics::instance()->getRemoteConfigValue("liquid_assets").toArray();

        const QString network_key = "liquid";

        for (const auto& value: liquid_assets) {
            const auto data = value.toObject();
            auto asset = assetWithId("mainnet", data.value("id").toString());
            asset->setNetworkKey(network_key);
            asset->setIsAmp(data.value("amp").toBool(false));
            asset->setWeight(data.value("weight").toInt(0));
        }
    });

    for (const auto network : NetworkManager::instance()->networks()) {
        const auto network_key = network->key();
        const auto id = network->data().value("policy_asset").toString("btc");
        const auto key = network->data().value("policy_asset").toString("btc");
        auto asset = assetWithId(network->deployment(), id);
        asset->setNetworkKey(network_key);
        asset->setPolicy(true);
        asset->setWeight(INT_MAX);
        asset->setKey(key);
        if (network->isLiquid() && network->isMainnet()) {
            asset->setName(network->displayName() + " Bitcoin");
        } else {
            asset->setName(network->displayName());
        }
    }
}

AssetManager::~AssetManager()
{
    g_asset_manager = nullptr;
}

AssetManager* AssetManager::instance()
{
    Q_ASSERT(g_asset_manager);
    return g_asset_manager;
}

AssetManager* AssetManager::create(QQmlEngine*, QJSEngine* engine)
{
    return AssetManager::instance();
}

Asset *AssetManager::assetWithId(const QString& deployment, const QString& id)
{
    Asset* asset = m_assets.value({ deployment, id });
    if (!asset) {
        asset = new Asset(deployment, id, this);
        m_assets.insert({ deployment, id }, asset);
        m_model->appendRow(asset->item());
    }
    Q_ASSERT(deployment == asset->deployment());
    return asset;
}

AssetsModel::AssetsModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setSourceModel(AssetManager::instance()->model());
    setDynamicSortFilter(true);
    setDynamicSortFilter(true);
    sort(0); // NOLINT(build/include_what_you_use)
}

void AssetsModel::setFilter(const QString& filter)
{
    if (m_filter == filter) return;
    m_filter = filter;
    emit filterChanged();
    invalidateRowsFilter();
}

void AssetsModel::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
    invalidateRowsFilter();
}

void AssetsModel::setMinWeight(int min_weight)
{
    if (m_min_weight == min_weight) return;
    m_min_weight = min_weight;
    emit minWeightChanged();
    invalidateRowsFilter();
}

bool AssetsModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    const auto index = sourceModel()->index(source_row, 0, source_parent);
    const auto asset = index.data(Qt::UserRole + 1).value<Asset*>();

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
