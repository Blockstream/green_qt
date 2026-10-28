#include "analytics.h"
#include "asset.h"
#include "assetmanager.h"
#include "green_settings.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"
#include "sessionmanager.h"
#include "task.h"

#include <QDebug>

static AssetManager* g_asset_manager{nullptr};

// Unregistered assets never get data and a failed fetch may keep failing, so
// automatic refreshes are rate limited from the last attempt.
constexpr qint64 kRefreshInterval = 5 * 60 * 1000;

AssetManager::AssetManager()
    : m_model(new QStandardItemModel(this))
    , m_dispatcher(new TaskDispatcher(this))
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

void AssetManager::start()
{
    if (m_started) return;
    m_started = true;
    auto settings = Settings::instance();
    load(QStringLiteral("mainnet"));
    if (settings->enableTestnet()) load(QStringLiteral("testnet"));
    connect(settings, &Settings::enableTestnetChanged, this, [=, this] {
        if (settings->enableTestnet()) load(QStringLiteral("testnet"));
    });
}

void AssetManager::load(const QString& deployment)
{
    if (m_registries.value(deployment).loaded) return;
    fetch(deployment);
}

void AssetManager::refresh(const QString& deployment)
{
    fetch(deployment);
}

void AssetManager::refreshIfStale(const QString& deployment)
{
    const auto& registry = m_registries.value(deployment);
    if (registry.timer.isValid() && registry.timer.elapsed() < kRefreshInterval) return;
    fetch(deployment);
}

void AssetManager::fetch(const QString& deployment)
{
    auto& registry = m_registries[deployment];
    if (registry.group) return;

    // One registry session at a time: concurrent first TLS connections race in gdk's electrum client.
    for (const auto& other : m_registries) {
        if (other.group) {
            if (!m_pending.contains(deployment)) m_pending.append(deployment);
            return;
        }
    }

    Network* network{nullptr};
    for (auto candidate : NetworkManager::instance()->networks()) {
        if (candidate->isLiquid() && candidate->isElectrum() && candidate->deployment() == deployment) {
            network = candidate;
            break;
        }
    }
    if (!network) return;

    registry.timer.start();
    auto session = SessionManager::instance()->create(network);
    session->setActive(true);

    auto group = new TaskGroup(this);
    group->setName(QStringLiteral("load assets %1").arg(deployment));
    auto connect_session = new ConnectTask(session);
    auto load_assets = new LoadAssetsTask(session);
    connect_session->then(load_assets);
    group->add(connect_session);
    group->add(load_assets);

    registry.session = session;
    registry.group = group;
    registry.tasks = { connect_session, load_assets };

    connect(group, &TaskGroup::finished, this, [=, this] {
        auto& registry = m_registries[deployment];
        registry.loaded = true;
        release(deployment);
    });
    connect(group, &TaskGroup::failed, this, [=, this] {
        qWarning() << "assets: failed to load" << deployment;
        release(deployment);
    });

    m_dispatcher->add(group);
}

void AssetManager::release(const QString& deployment)
{
    auto& registry = m_registries[deployment];
    if (registry.group) {
        registry.group->deleteLater();
        registry.group = nullptr;
    }
    registry.tasks.clear();
    if (registry.session) {
        SessionManager::instance()->release(registry.session);
        registry.session = nullptr;
    }
    if (!m_pending.isEmpty()) {
        fetch(m_pending.takeFirst());
    }
}

void AssetManager::stop()
{
    m_pending.clear();
    for (auto i = m_registries.begin(); i != m_registries.end(); ++i) {
        // Detach the group first so deleting a task does not dispatch the others.
        delete i->group;
        i->group = nullptr;
        // Task destructors wait for in-flight gdk calls before the session goes away.
        qDeleteAll(i->tasks);
        i->tasks.clear();
        release(i.key());
    }
}
