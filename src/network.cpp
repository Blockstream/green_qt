#include "network.h"
#include "ga.h"
#include "json.h"

#include <QDesktopServices>
#include <QUrl>

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
    return QQmlListProperty<Network>(this, m_networks);
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

Network::Network(const QJsonObject &data, NetworkManager *manager)
    : QObject(manager)
    , m_data(data)
{
    Q_ASSERT(data.contains("network"));
    Q_ASSERT(data.contains("name"));
    m_id = data.value("network").toString();
    m_name = data.value("name").toString();
}

bool Network::isLiquid() const
{
    return m_data.value("liquid").toBool();
}

void Network::openTransactionInExplorer(const QString& hash)
{
    Q_ASSERT(m_data.contains("tx_explorer_url"));
    auto tx_explorer_url = m_data.value("tx_explorer_url").toString();
    Q_ASSERT(tx_explorer_url.endsWith("/"));
    QDesktopServices::openUrl(QUrl(tx_explorer_url + hash));
}
