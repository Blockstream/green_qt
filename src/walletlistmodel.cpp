#include "context.h"
#include "network.h"
#include "wallet.h"
#include "walletlistmodel.h"
#include "walletmanager.h"

WalletListModel::WalletListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    update();
    m_source_model.setItemRoleNames({{ Qt::UserRole, "wallet" }});
    connect(WalletManager::instance(), &WalletManager::changed, this, &WalletListModel::update, Qt::QueuedConnection);
    setSourceModel(&m_source_model);
    setDynamicSortFilter(true);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    sort(0); // NOLINT(build/include_what_you_use)
}

int WalletListModel::indexOf(Wallet *wallet) const
{
    for (int i = 0; i < rowCount(); ++i) {
        if (data(index(i, 0), Qt::UserRole).value<Wallet*>() == wallet) return i;
    }
    return -1;
}

void WalletListModel::update()
{
    auto items = m_items;
    m_items.clear();
    for (auto wallet : WalletManager::instance()->m_wallets) {
        auto item = items.take(wallet);
        if (!item) {
            item = new QStandardItem;
            item->setData(QVariant::fromValue(wallet), Qt::UserRole);
            m_source_model.appendRow(item);
            connect(wallet, &Wallet::contextChanged, this, [this] { invalidateFilter(); });
        }
        m_items.insert(wallet, item);
    }
    for (auto item : items.values()) {
        m_source_model.takeRow(item->row());
    }
    qDeleteAll(items.values());
}

bool WalletListModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    auto wallet = m_source_model.index(source_row, 0, source_parent).data(Qt::UserRole).value<Wallet*>();
    auto watchonly_data = qobject_cast<WatchonlyData*>(wallet->login());
    if (m_watch_only == Filter::Yes && !watchonly_data) return false;
    if (m_watch_only == Filter::No && watchonly_data) return false;
    auto pin_data = qobject_cast<PinData*>(wallet->login());
    if (m_filter_pin_data == Filter::Yes && !pin_data) return false;
    if (m_filter_pin_data == Filter::No && pin_data) return false;
    auto device_data = qobject_cast<DeviceData*>(wallet->login());
    if (m_filter_device_details == Filter::Yes && !device_data) return false;
    if (m_filter_device_details == Filter::No && device_data) return false;
    return filterRegularExpression().match(wallet->name()).hasMatch();
}

bool WalletListModel::lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const
{
    auto wallet_left = source_left.data(Qt::UserRole).value<Wallet*>();
    auto wallet_right = source_right.data(Qt::UserRole).value<Wallet*>();
    return QString::localeAwareCompare(wallet_left->name(), wallet_right->name()) < 0;
}

void WalletListModel::setWatchOnly(WalletListModel::Filter watch_only)
{
    if (m_watch_only == watch_only) return;
    m_watch_only = watch_only;
    emit watchOnlyChanged(m_watch_only);
    invalidateFilter();
}

void WalletListModel::setFilterPinData(Filter filter_pin_data)
{
    if (m_filter_pin_data == filter_pin_data) return;
    m_filter_pin_data = filter_pin_data;
    emit filterPinDataChanged();
    invalidateFilter();
}

void WalletListModel::setFilterDeviceDetails(Filter filter_device_details)
{
    if (m_filter_device_details == filter_device_details) return;
    m_filter_device_details = filter_device_details;
    emit filterDeviceDetailsChanged();
    invalidateFilter();
}
