#include "networkmanager.h"

#include <gdk.h>

#include "ga.h"
#include "json.h"
#include "network.h"

static QJsonObject get_networks()
{
    GA_json* output;
    int err = GA_get_networks(&output);
    Q_ASSERT(err == GA_OK);
    auto networks = Json::toObject(output);
    err = GA_destroy_json(output);
    Q_ASSERT(err == GA_OK);
    return networks;
}

NetworkManager::NetworkManager() : QObject(nullptr)
{
    auto networks = get_networks();
    for (auto key : networks.value("all_networks").toArray()) {
        auto data = networks.value(key.toString()).toObject();
        m_networks.append(new Network(data, this));
    }
}

NetworkManager *NetworkManager::instance()
{
    static NetworkManager* network_manager = nullptr;
    if (!network_manager) network_manager = new NetworkManager;
    return network_manager;
}

NetworkManager* NetworkManager::create(QQmlEngine *, QJSEngine *engine)
{
    return instance();
}

QList<Network *> NetworkManager::networks() const
{
    return m_networks;
}

Network *NetworkManager::network(const QString &id) const
{
    for (auto network : m_networks) {
        if (network->id() == id) {
            return network;
        }
    }
    return nullptr;
}

Network *NetworkManager::networkWithServerType(const QString& deployment, const QString& key, const QString& server_type) const
{
    for (auto network : m_networks) {
        if (network->deployment() == deployment &&
            network->key() == key &&
            network->data().value("server_type").toString() == server_type) {
            return network;
        }
    }
    return nullptr;
}

Network *NetworkManager::networkForDeployment(const QString &deployment)
{
    if (deployment == "mainnet") return network("electrum-mainnet");
    if (deployment == "testnet") return network("electrum-testnet");
    Q_UNREACHABLE();
}
