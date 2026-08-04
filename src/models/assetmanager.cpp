#include "analytics.h"
#include "asset.h"
#include "assetmanager.h"
#include "network.h"
#include "networkmanager.h"

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

        for (const auto& value: liquid_assets) {
            const auto data = value.toObject();
            auto asset = assetWithId("mainnet", data.value("id").toString());
            asset->setIsAmp(data.value("amp").toBool(false));
            asset->setWeight(data.value("weight").toInt(0));
        }
    });

    for (const auto network : NetworkManager::instance()->networks()) {
        const auto id = network->data().value("policy_asset").toString("btc");
        const auto key = network->data().value("policy_asset").toString("btc");
        auto asset = assetWithId(network->deployment(), id);
        asset->setPolicy(true);
        asset->setWeight(network->isLiquid() ? INT_MAX - 2 : INT_MAX);
        asset->setKey(key);
        if (network->isLiquid() && network->isMainnet()) {
            asset->setName(network->displayName() + " Bitcoin");
        } else {
            asset->setName(network->displayName());
        }
    }

    auto lightning_asset = assetWithId(QStringLiteral("mainnet"), QString::fromLatin1(kLightningAssetId));
    lightning_asset->setWeight(INT_MAX - 1);
    lightning_asset->setName(QStringLiteral("Lightning Bitcoin"));
    lightning_asset->setIcon(QStringLiteral("qrc:/svg3/lightning.svg"));
    lightning_asset->setData({
        { QStringLiteral("name"), QStringLiteral("Lightning Bitcoin") },
        { QStringLiteral("ticker"), QStringLiteral("BTC") },
        { QStringLiteral("precision"), 8 },
    });
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
