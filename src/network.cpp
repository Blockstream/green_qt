#include "network.h"
#include "ga.h"
#include "json.h"

#include <gdk.h>

#include <QDesktopServices>
#include <QUrl>

Network::Network(const QJsonObject &data, QObject *parent)
    : QObject(parent)
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
