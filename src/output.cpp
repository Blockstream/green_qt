#include "account.h"
#include "asset.h"
#include "context.h"
#include "json.h"
#include "network.h"
#include "output.h"
#include "session.h"
#include "util.h"
#include "wallet.h"

#include <gdk.h>

Output::Output(const QJsonObject& data, Account* account)
    : QObject(account)
    , m_account(account)
{
    updateFromData(data);
    connect(m_account->session(), &Session::blockChanged, this, &Output::updateExpired);
}

void Output::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();
    update();
}

void Output::update()
{
    const auto network = m_account->network();
    if (!m_asset && network->isLiquid()) {
        auto asset_id = m_data["asset_id"].toString();
        m_asset = m_account->context()->getOrCreateAsset(network, asset_id);
        emit assetChanged();
    }

    setDust(m_data["satoshi"].toDouble() < 1092 && !network->isLiquid());
    setCanBeLocked(m_data["satoshi"].toDouble() < 2184);
    setLocked(m_data["user_status"].toInt() == 1);
    setConfidential(m_data["is_confidential"].toBool());
    setUnconfirmed(m_data["block_height"].toDouble() == 0);
    setAddressType(m_data["address_type"].toString());
    updateExpired();
}

void Output::updateExpired()
{
    const auto expiry_height = m_data.value("expiry_height");
    if (expiry_height.isDouble()) {
        const auto block_height = m_account->session()->blockHeight();
        setExpired(expiry_height.toDouble() <= block_height);
    } else {
        setExpired(false);
    }
}

void Output::setExpired(bool expired)
{
    if (m_expired == expired) return;
    m_expired = expired;
    emit expiredChanged();
}

void Output::setDust(bool dust)
{
    if (m_dust == dust) return;
    m_dust = dust;
    emit dustChanged();
}

void Output::setLocked(bool locked)
{
    if (m_locked == locked) return;
    m_locked = locked;
    emit lockedChanged();
}

void Output::setCanBeLocked(bool can_be_locked)
{
    if (m_can_be_locked == can_be_locked) return;
    m_can_be_locked = can_be_locked;
    emit canBeLockedChanged();
}

void Output::setConfidential(bool confidential)
{
    if (m_confidential == confidential) return;
    m_confidential = confidential;
    emit confidentialChanged();
}

void Output::setUnconfirmed(bool unconfirmed)
{
    if (m_unconfirmed == unconfirmed) return;
    m_unconfirmed = unconfirmed;
    emit unconfirmedChanged();
}

void Output::setAddressType(const QString& address_type)
{
    if (m_address_type == address_type) return;
    m_address_type = address_type;
    emit addressTypeChanged();
}
