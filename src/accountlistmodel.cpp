#include "account.h"
#include "accountlistmodel.h"
#include "context.h"
#include "wallet.h"

AccountListModel::AccountListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
}

void AccountListModel::setContext(Context* context)
{
    if (m_context == context) return;
    if (m_context) {
        setSourceModel(nullptr);
        m_items.clear();
        delete m_model;
    }
    m_context = context;
    if (m_context) {
        m_model = new QStandardItemModel(this);
        m_model->setItemRoleNames({{ Qt::UserRole, "account" }});
        update();
        setSourceModel(m_model);
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
