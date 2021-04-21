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

Output::~Output()
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

QString Output::formatAmount(bool include_ticker) const
{
    if (m_asset) {
        return m_asset->formatAmount(m_data["satoshi"].toDouble(), include_ticker);
    } else {
        return m_account->wallet()->formatAmount(m_data["satoshi"].toDouble(), include_ticker);
    }
}

