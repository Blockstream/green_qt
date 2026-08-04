#include "asset.h"
#include "network.h"
#include "networkmanager.h"

#include <QLocale>
#include <QtMath>

namespace {

QString GetNetworkKey(const QString& deployment, const QString& id)
{
    if (id == QLatin1String(kLightningAssetId)) return QStringLiteral("lightning");

    const bool liquid = (id != "btc");
    for (const auto network : NetworkManager::instance()->networks()) {
        if (network->deployment() == deployment && network->isLiquid() == liquid) {
            return network->key();
        }
    }
    Q_UNREACHABLE();
}

} // namespace

Asset::Asset(const QString& deployment, const QString& id, QObject* parent)
    : QObject(parent)
    , m_deployment(deployment)
    , m_id(id)
    , m_network_key(GetNetworkKey(deployment, id))
    , m_key(id)
    , m_item(new QStandardItem)
{
    m_item->setData(QVariant::fromValue(this));
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

bool Asset::isLightning() const
{
    return m_id == QLatin1String(kLightningAssetId);
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
    if (!network) return {};
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
