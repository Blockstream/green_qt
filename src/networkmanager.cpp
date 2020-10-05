#include "network.h"
#include "networkmanager.h"
#include "ga.h"
#include "json.h"

#include <gdk.h>

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
        // Don't include development networks
        if (data.value("development").toBool()) continue;
        // Don't include electrum networks
        if (data.contains("server_type") && data.value("server_type").toString() == "electrum") continue;
        m_networks.append(new Network(data, this));
    }
}

NetworkManager *NetworkManager::instance()
{
    static NetworkManager network_manager;
    return &network_manager;
}

QQmlListProperty<Network> NetworkManager::networks()
{
    return { this, &m_networks };
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
