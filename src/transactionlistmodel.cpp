#include "activitymanager.h"
#include "account.h"
#include "resolver.h"
#include "transaction.h"
#include "transactionlistmodel.h"

#include <QDebug>

TransactionListModel::TransactionListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_reload_timer(new QTimer(this))
{
    m_reload_timer->setSingleShot(true);
    m_reload_timer->setInterval(200);
    connect(m_reload_timer, &QTimer::timeout, [this] {
        m_reached_end = false;
        m_has_unconfirmed = false;
        fetch(true, 0, 30);
    });
}

TransactionListModel::~TransactionListModel()
{

}

void TransactionListModel::setAccount(Account *account)
{
    if (m_account) {
        beginResetModel();
        m_reached_end = false;
        m_get_transactions_activity.update(nullptr);
        m_transactions.clear();
        disconnect(m_account, &Account::notificationHandled, this, &TransactionListModel::handleNotification);
        m_account = nullptr;
        emit accountChanged(nullptr);
        endResetModel();
    }
    if (!account) return;
    m_account = account;
    emit accountChanged(account);
    if (m_account) {
        connect(m_account, &Account::notificationHandled, this, &TransactionListModel::handleNotification);
        fetchMore(QModelIndex());
    }
}

void TransactionListModel::handleNotification(const QJsonObject& notification)
{
    QString event = notification.value("event").toString();
    if (event == "transaction") {
        reload();
        return;
    }

    if (event == "block" && m_has_unconfirmed) {
        reload();
        return;
    }
}

void TransactionListModel::fetch(bool reset, int offset, int count)
{
    m_get_transactions_activity.update(new AccountGetTransactionsActivity(m_account, offset, count, this));
    m_account->wallet()->pushActivity(m_get_transactions_activity);

    m_get_transactions_activity.track(QObject::connect(m_get_transactions_activity, &Activity::finished, this, [this, reset] {
        for (auto transaction : m_get_transactions_activity->transactions()) {
            if (transaction->isUnconfirmed()) m_has_unconfirmed = true;
        }
        m_reached_end = m_get_transactions_activity->transactions().empty();
        if (reset) {
            // just swap rows instead of incremental update
            // this happens after a bump fee for instance
            beginResetModel();
            m_transactions = m_get_transactions_activity->transactions();
            endResetModel();
        } else {
            // new page of transactions, just append to existing transaction
            beginInsertRows(QModelIndex(), m_transactions.size(), m_transactions.size() + m_get_transactions_activity->transactions().size() - 1);
            m_transactions.append(m_get_transactions_activity->transactions());
            endInsertRows();
        }

        m_get_transactions_activity->deleteLater();
        m_get_transactions_activity.update(0);
        emit fetchingChanged();
    }));

    ActivityManager::instance()->exec(m_get_transactions_activity);
    emit fetchingChanged();
}

QHash<int, QByteArray> TransactionListModel::roleNames() const
{
    return {
        { Qt::UserRole, "transaction" }
    };
}

bool TransactionListModel::canFetchMore(const QModelIndex &parent) const
{
    Q_ASSERT(!parent.parent().isValid());
    if (m_reached_end) return false;
    // Prevent concurrent fetchMore
    if (m_get_transactions_activity) return false;
    return true;
}

void TransactionListModel::fetchMore(const QModelIndex &parent)
{
    Q_ASSERT(!parent.parent().isValid());
    if (!m_account) return;
    if (m_get_transactions_activity) return;
    fetch(false, m_transactions.size(), 30);
}

int TransactionListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_transactions.size();
}

int TransactionListModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return 1;
}

QVariant TransactionListModel::data(const QModelIndex &index, int role) const
{
    if (role == Qt::UserRole) return QVariant::fromValue(m_transactions.at(index.row()));
    return QVariant();
}

void TransactionListModel::reload()
{
    if (!m_account) return;
    m_reload_timer->start();
}

TransactionFilterProxyModel::TransactionFilterProxyModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

void TransactionFilterProxyModel::setModel(TransactionListModel* model)
{
    if (m_model == model) return;
    m_model = model;
    emit modelChanged(m_model);
    setSourceModel(m_model);
    connect(m_model, &TransactionListModel::fetchingChanged, this, [this] {
        if (!m_filter.isEmpty() && m_model->canFetchMore({})) m_model->fetchMore({});
    });
}

void TransactionFilterProxyModel::setFilter(const QString& filter)
{
    if (m_filter == filter) return;
    m_filter = filter;
    emit filterChanged(m_filter);
    invalidateFilter();
    if (!m_filter.isEmpty() && !m_model->fetching()) m_model->fetchMore(QModelIndex{});
}

int TransactionFilterProxyModel::maxRowCount() const
{
    return m_max_row_count;
}

void TransactionFilterProxyModel::setMaxRowCount(int max_row_count)
{
    m_max_row_count = max_row_count;
    emit maxRowCountChanged(max_row_count);
}

bool TransactionFilterProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    if (m_max_row_count >- 1 && source_row >= m_max_row_count) return false;
    if (m_filter.isEmpty()) return true;
    auto transaction = m_model->index(source_row, 0, source_parent).data(Qt::UserRole).value<Transaction*>();
    if (transaction->hash().contains(m_filter, Qt::CaseInsensitive)) return true;
    if (transaction->memo().contains(m_filter, Qt::CaseInsensitive)) return true;
    return false;
}
