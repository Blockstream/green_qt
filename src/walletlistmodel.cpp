#include "network.h"
#include "wallet.h"
#include "walletlistmodel.h"
#include "walletmanager.h"

WalletListModel::WalletListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    update();
    m_source_model.setItemRoleNames({{ Qt::UserRole, "wallet" }});
    connect(WalletManager::instance(), &WalletManager::changed, this, &WalletListModel::update);
    setSourceModel(&m_source_model);
    setDynamicSortFilter(true);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    sort(0);
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
    return filterRegExp().indexIn(wallet->name()) >= 0;
}

bool WalletListModel::lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const
{
    auto wallet_left = source_left.data(Qt::UserRole).value<Wallet*>();
    auto wallet_right = source_right.data(Qt::UserRole).value<Wallet*>();
    auto network_left = wallet_left->network();
    auto network_right = wallet_right->network();
    if (network_left == network_right) {
        return QString::localeAwareCompare(wallet_left->name(), wallet_right->name()) < 0;
    }
    return QString::localeAwareCompare(network_left->name(), network_right->name()) < 0;
}
