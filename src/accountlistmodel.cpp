#include "account.h"
#include "accountlistmodel.h"
#include "context.h"
#include "network.h"
#include "wallet.h"

AccountListModel::AccountListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

void AccountListModel::setContext(Context* context)
{
    if (m_context == context) return;
    if (m_context) {
        setSourceModel(nullptr);
        emit countChanged();
        m_items.clear();
        delete m_model;
    }
    m_context = context;
    if (m_context) {
        m_model = new QStandardItemModel(this);
        m_model->setItemRoleNames({{ Qt::UserRole, "account" }});
        update();
        setSourceModel(m_model);
        setDynamicSortFilter(true);
        sort(0); // NOLINT(build/include_what_you_use)
        connect(m_context, &Context::accountsChanged, this, [=] {
            update();
            invalidateRowsFilter();
        });
    }
    emit contextChanged();
}

void AccountListModel::update()
{
    Q_ASSERT(m_context);
    Q_ASSERT(m_model);
    bool changed = false;
    for (Account* account : m_context->m_accounts) {
        if (m_items.contains(account)) continue;
        changed = true;
        auto item = new QStandardItem;
        m_items.insert(account, item);
        item->setData(QVariant::fromValue(account), Qt::UserRole);
        m_model->appendRow(item);
        connect(account, &Account::nameChanged, this, &AccountListModel::invalidateFilterAndCount);
        connect(account, &Account::hiddenChanged, this, &AccountListModel::invalidateFilterAndCount);
        connect(account, &Account::balanceChanged, this, &AccountListModel::invalidateFilterAndCount);
        connect(account, &Account::balancesChanged, this, &AccountListModel::invalidateFilterAndCount);
    }
    if (changed) emit countChanged();
}

void AccountListModel::invalidateFilterAndCount()
{
    invalidateRowsFilter();
    emit countChanged();
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
    emit filterChanged();
    invalidateFilterAndCount();
}

static int index(Account* account)
{
    if (account->isBitcoin() && account->isSinglesig()) return 0;
    if (account->isBitcoin() && account->isMultisig()) return 1;
    if (account->isLightning()) return 2;
    if (account->isLiquid() && account->isSinglesig()) return 3;
    if (account->isLiquid() && account->isMultisig() && !account->isAmp()) return 4;
    if (account->isLiquid() && account->isMultisig() && account->isAmp()) return 5;
    return 6;
}

static int weight(Account* account)
{
    int offset = account->network()->isMainnet() ? 0 : account->network()->isDevelopment() ? 20 : 10;
    return offset + index(account);
}

bool AccountListModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    auto account_left = source_left.data(Qt::UserRole).value<Account*>();
    auto account_right = source_right.data(Qt::UserRole).value<Account*>();

    auto weight_left = weight(account_left);
    auto weight_right = weight(account_right);

    if (weight_left == weight_right) {
        return account_left->pointer() < account_right->pointer();
    }

    return weight_left < weight_right;
}

Account *AccountListModel::first() const
{
    return accountAt(0);
}

Account* AccountListModel::accountAt(int row) const
{
    return data(index(row, 0), Qt::UserRole).value<Account*>();
}

int AccountListModel::indexOf(Account* account) const
{
    for (int i = 0; i < rowCount(); i++) {
        if (accountAt(i) == account) {
            return i;
        }
    }
    return -1;
}
