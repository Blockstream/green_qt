#include "addresslistmodel.h"

#include "account.h"
#include "address.h"
#include "context.h"
#include "task.h"

AddressListModel::AddressListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

void AddressListModel::setAccount(Account* account)
{
    if (m_account == account) return;
    if (m_account) {
        setSourceModel(nullptr);
        delete m_model;
        m_items.clear();
        disconnect(m_account, &Account::addressGenerated, this, &AddressListModel::update);
    }
    m_account = account;
    if (m_account) {
        m_model = new QStandardItemModel(this);
        m_model->setItemRoleNames({{ Qt::UserRole, "address" }});
        m_last_pointer = 0;
        m_loaded.clear();
        setSourceModel(m_model);
        setDynamicSortFilter(true);
        sort(0); // NOLINT(build/include_what_you_use)
        connect(m_account, &Account::addressGenerated, this, &AddressListModel::update);
    }
    emit accountChanged();
}

void AddressListModel::update()
{
    load(0, m_last_pointer != 0);
}

void AddressListModel::load(int last_pointer, bool head)
{
    if (last_pointer > 0 && m_loaded.contains(last_pointer)) return;
    m_loaded.insert(last_pointer);
    auto task = new GetAddressesTask(last_pointer, m_account);
    connect(task, &Task::finished, this, [=] {
        for (QJsonValue data : task->addresses()) {
            auto address = m_account->getOrCreateAddress(data.toObject());
            if (m_items.contains(address)) return;
            auto item = new QStandardItem;
            m_items.insert(address, item);
            item->setData(QVariant::fromValue(address), Qt::UserRole);
            m_model->appendRow(item);
        }
        if (head) {
            load(task->lastPointer(), true);
        } else {
            m_last_pointer = task->lastPointer();
            if (!m_filter.isEmpty()) {
                load(m_last_pointer, false);
            }
        }
    });
    m_account->context()->dispatcher()->add(task);
}

bool AddressListModel::lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const
{
    auto address_left = source_left.data(Qt::UserRole).value<Address*>();
    auto address_right = source_right.data(Qt::UserRole).value<Address*>();
    return address_left->pointer() > address_right->pointer();
}

bool AddressListModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (!m_filter.isEmpty()) {
        auto address = m_model->index(source_row, 0, source_parent).data(Qt::UserRole).value<Address*>();
        if (!address->address().contains(m_filter, Qt::CaseInsensitive)) return false;
        return true;
    }
    return QSortFilterProxyModel::filterAcceptsRow(source_row, source_parent);
}

void AddressListModel::setFilter(const QString& filter)
{
    if (m_filter == filter) return;
    m_filter = filter;
    emit filterChanged();
    invalidateFilter();
}

void AddressListModel::fetchMore(const QModelIndex& parent)
{
    load(m_last_pointer, false);
}

bool AddressListModel::canFetchMore(const QModelIndex& parent) const
{
    return m_account && m_last_pointer >= 0;
}
