#include "account.h"
#include "asset.h"
#include "balance.h"
#include "wallet.h"

Balance::Balance(Account* account)
    : QObject(account)
    , m_account(account)
{
    Q_ASSERT(account);

    // Display/input amount might change if settings are updated
    connect(m_account->wallet(), &Wallet::settingsChanged, this, &Balance::changed);
}

void Balance::setAsset(Asset* asset)
{
    // Either it's the first call or asset can't change
    Q_ASSERT(!m_asset || m_asset == asset);
    m_asset = asset;
    emit assetChanged(m_asset);
    emit changed();

    // Asset might not be loaded
    connect(m_asset, &Asset::dataChanged, this, &Balance::changed);
}

void Balance::setAmount(qint64 amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    emit changed();
}

QString Balance::displayAmount() const
{
    Q_ASSERT(m_asset);
    return m_asset->formatAmount(m_amount, /* include_ticker = */ true);
}

QString Balance::inputAmount() const
{
    Q_ASSERT(m_asset);
    return m_asset->formatAmount(m_amount, /* include_ticker = */ false);
}
