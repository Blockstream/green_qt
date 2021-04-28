#include "account.h"
#include "asset.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "output.h"
#include "util.h"
#include "wallet.h"
#include <gdk.h>

Output::Output(Account* account)
    : QObject(account)
    , m_account(account)
{
}

void Output::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged(m_data);

    if (!m_asset && m_account->wallet()->network()->isLiquid()) {
        auto asset_id = data["asset_id"].toString();
        m_asset = m_account->wallet()->getOrCreateAsset(asset_id);
        emit assetChanged(m_asset);
    }
}

bool Output::dust() const
{
    return data()["satoshi"].toDouble() < 1092;
}

bool Output::locked() const
{
    return data()["user_status"].toInt() == 1;
}

bool Output::confidential() const
{
    return data()["confidential"].toBool();
}

bool Output::expired() const
{
    if (m_data["address_type"] == "csv") {
        auto block_height = m_data["block_height"].toDouble() + m_data["subtype"].toDouble();
        auto current_block_height = account()->wallet()->events()["block"].toObject()["block_height"].toDouble();
        return block_height < current_block_height;
    } else {
        return m_data["nlocktime_at"].toInt() == 0;
    }
}

bool Output::unconfirmed() const
{
    return data()["block_height"].toDouble() == 0;
}

QString Output::addressType() const
{
    return data()["address_type"].toString();
}

