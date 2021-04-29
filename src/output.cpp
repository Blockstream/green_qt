#include "account.h"
#include "asset.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "output.h"
#include "util.h"
#include "wallet.h"
#include <gdk.h>

Output::Output(const QJsonObject& data, Account* account)
    : QObject(account)
    , m_account(account)
{
    updateFromData(data);
}

void Output::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged(m_data);
    update();
}

void Output::update()
{
    if (!m_asset && m_account->wallet()->network()->isLiquid()) {
        auto asset_id = m_data["asset_id"].toString();
        m_asset = m_account->wallet()->getOrCreateAsset(asset_id);
        emit assetChanged(m_asset);
    }

    setDust(m_data["satoshi"].toDouble() < 1092);
    setLocked(m_data["user_status"].toInt() == 1);
    setConfidential(m_data["confidential"].toBool());
    setUnconfirmed(m_data["block_height"].toDouble() == 0);
    setAddressType(m_data["address_type"].toString());
    if (m_address_type == "csv") {
        auto block_height = m_data["block_height"].toDouble() + m_data["subtype"].toDouble();
        auto current_block_height = m_account->wallet()->events()["block"].toObject()["block_height"].toDouble();
        setExpired(block_height < current_block_height);
    } else {
        setExpired(m_data["nlocktime_at"].toInt() == 0);
    }
}

void Output::setDust(bool dust)
{
    if (m_dust == dust) return;
    m_dust = dust;
    emit dustChanged(m_dust);
}

void Output::setLocked(bool locked)
{
    if (m_locked == locked) return;
    m_locked = locked;
    emit lockedChanged(m_locked);
}

void Output::setConfidential(bool confidential)
{
    if (m_confidential == confidential) return;
    m_confidential = confidential;
    emit confidentialChanged(m_confidential);
}

void Output::setExpired(bool expired)
{
    if (m_expired == expired) return;
    m_expired = expired;
    emit expiredChanged(m_expired);
}

void Output::setUnconfirmed(bool unconfirmed)
{
    if (m_unconfirmed == unconfirmed) return;
    m_unconfirmed = unconfirmed;
    emit expiredChanged(m_unconfirmed);
}

void Output::setSelected(bool selected)
{
    if (m_selected == selected) return;
    m_selected = selected;
    emit expiredChanged(m_selected);
}

void Output::setAddressType(const QString& address_type)
{
    if (m_address_type == address_type) return;
    m_address_type = address_type;
    emit addressTypeChanged(m_address_type);
}

