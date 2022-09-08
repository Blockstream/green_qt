#include "account.h"
#include "accountlistmodel.h"
#include "wallet.h"

AccountListModel::AccountListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
}

void AccountListModel::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet) return;
    if (m_wallet) {
        setSourceModel(nullptr);
        m_items.clear();
        delete m_model;
    }
    m_wallet = wallet;
    if (m_wallet) {
        m_model = new QStandardItemModel(this);
        m_model->setItemRoleNames({{ Qt::UserRole, "account" }});
        update();
        setSourceModel(m_model);
        connect(m_wallet, &Wallet::accountsChanged, this, [=] {
            update();
            invalidateFilter();
        });
    }
    emit walletChanged(m_wallet);
}

void AccountListModel::update()
{
    Q_ASSERT(m_wallet);
    Q_ASSERT(m_model);
    for (Account* account : m_wallet->m_accounts) {
        if (m_items.contains(account)) continue;
        auto item = new QStandardItem;
        m_items.insert(account, item);
        item->setData(QVariant::fromValue(account), Qt::UserRole);
        m_model->appendRow(item);
        connect(account, &Account::hiddenChanged, this, [=] { invalidateFilter(); });
        connect(account, &Account::balanceChanged, this, [=] { invalidateFilter(); });
        connect(account, &Account::balancesChanged, this, [=] { invalidateFilter(); });
    }
}

bool AccountListModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    Q_ASSERT(m_model);
    auto account = m_model->index(source_row, 0, source_parent).data(Qt::UserRole).value<Account*>();

    for (QString filter : m_filter.split(' ', Qt::SkipEmptyParts)) {
        bool invert = filter.startsWith('!');
        if (invert) filter = filter.mid(1);
        bool result = true;
        if (filter == "hidden") result = account->isHidden();
        if (invert) result = !result;
        if (!result) return false;
    }

    return QSortFilterProxyModel::filterAcceptsRow(source_row, source_parent);
}

void AccountListModel::setFilter(const QString &filter)
{
    if (m_filter == filter) return;
    m_filter = filter;
    emit filterChanged(m_filter);
    invalidateFilter();
}
