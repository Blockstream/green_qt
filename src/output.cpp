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

bool Output::dust()
{
    return data()["satoshi"].toDouble()<1092;
}

bool Output::locked()
{
    return data()["user_status"].toInt()==1;
}

bool Output::confidential()
{
    return data()["confidential"].toBool();
}

bool Output::expired()
{
    if (data()["address_type"]=="csv") {
        auto block_height = data()["block_height"].toDouble()+data()["subtype"].toDouble();
        auto current_block_height = account()->wallet()->events()["block"].toObject()["block_height"].toDouble();
        return block_height < current_block_height;
    } else {
        return data()["nlocktime_at"].toInt()==0;
    }
}

bool Output::unconfirmed()
{
    return data()["block_height"].toDouble()==0;
}

QString Output::addressType()
{
    return data()["address_type"].toString();
}

