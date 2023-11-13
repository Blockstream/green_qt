#include "network.h"

#include <gdk.h>

#include <QDesktopServices>
#include <QUrl>

#include "ga.h"
#include "json.h"

namespace {

QString GetNetworkKey(const QJsonObject& data)
{
    const auto mainnet = data.value("mainnet").toBool();
    const auto liquid = data.value("liquid").toBool();
    const auto development = data.value("development").toBool();
    if (mainnet && !liquid) return "bitcoin";
    if (mainnet && liquid) return "liquid";
    if (development && !liquid) return "localtest";
    if (development && liquid) return "localtest-liquid";
    if (!liquid) return "testnet";
    if (liquid) return "testnet-liquid";
    Q_UNREACHABLE();
}

QString GetNetworkDisplayName(const QJsonObject& data)
{
    const auto mainnet = data.value("mainnet").toBool();
    const auto liquid = data.value("liquid").toBool();
    const auto development = data.value("development").toBool();
    if (mainnet && !liquid) return "Bitcoin";
    if (mainnet && liquid) return "Liquid";
    if (development && !liquid) return "Localtest";
    if (development && liquid) return "Localtest Liquid";
    if (!liquid) return "Testnet";
    if (liquid) return "Testnet Liquid";
    Q_UNREACHABLE();
}

}

Network::Network(const QJsonObject& data, QObject *parent)
    : QObject(parent)
    , m_data(data)
    , m_id(data.value("network").toString())
    , m_canonical_id(data.value("network").toString().replace("electrum-", ""))
    , m_key(GetNetworkKey(data))
    , m_display_name(GetNetworkDisplayName(data))
    , m_name(data.value("name").toString())
    , m_mainnet(data.value("mainnet").toBool())
    , m_liquid(data.value("liquid").toBool())
    , m_electrum(data.value("server_type").toString() == "electrum")
    , m_development(data.value("development").toBool())
    , m_policy_asset(data.value("policy_asset").toString())
{
}

QString Network::policyAsset() const
{
    Q_ASSERT(m_liquid);
    return m_policy_asset;
}

QString Network::explorerUrl() const
{
    Q_ASSERT(m_data.contains("tx_explorer_url"));
    auto tx_explorer_url = m_data.value("tx_explorer_url").toString();
    if (!tx_explorer_url.isEmpty()) {
        Q_ASSERT(tx_explorer_url.endsWith("/"));
    }
    return tx_explorer_url;
}

void Network::openTransactionInExplorer(const QString& hash)
{
    const auto explorer_url = explorerUrl();
    if (!explorer_url.isEmpty()) {
        QDesktopServices::openUrl(QUrl(explorer_url + hash));
    }
}

QString Network::deployment() const
{
    if (m_mainnet) return "mainnet";
    if (m_development) return "development";
    return "testnet";
}
