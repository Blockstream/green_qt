#include "transactionlistmodel.h"

#include <QDebug>

#include "account.h"
#include "context.h"
#include "task.h"
#include "transaction.h"

TransactionListModel::TransactionListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_reload_timer(new QTimer(this))
{
    m_reload_timer->setSingleShot(true);
    m_reload_timer->setInterval(200);
    connect(m_reload_timer, &QTimer::timeout, this, [=] {
        beginResetModel();
        m_transactions.clear();
        endResetModel();
        m_has_unconfirmed = false;
        fetch(0, 30);
    });
}

void TransactionListModel::setAccount(Account *account)
{
    if (m_account) {
        beginResetModel();
        m_transactions.clear();
        disconnect(m_account, &Account::blockEvent, this, &TransactionListModel::handleBlockEvent);
        disconnect(m_account, &Account::transactionEvent, this, &TransactionListModel::handleTransactionEvent);
        m_account = nullptr;
        emit accountChanged();
        endResetModel();
    }
    if (!account) return;
    m_account = account;
    emit accountChanged();
    if (m_account) {
        connect(m_account, &Account::blockEvent, this, &TransactionListModel::handleBlockEvent);
        connect(m_account, &Account::transactionEvent, this, &TransactionListModel::handleTransactionEvent);
        reload();
    }
}

void TransactionListModel::fetch(int offset, int count)
{
    if (!m_account) return;

    if (m_get_transactions) return;

    m_get_transactions = new GetTransactionsTask(offset, count, m_account);

    connect(m_get_transactions, &Task::finished, this, [=] {
        QVector<Transaction*> transactions;
        for (const QJsonValue& value : m_get_transactions->transactions()) {
            auto transaction = account()->getOrCreateTransaction(value.toObject());
            transactions.append(transaction);
        }
        for (auto transaction : transactions) {
            if (transaction->isUnconfirmed()) m_has_unconfirmed = true;
            break;
        }

        if (transactions.size() > 0) {
            const auto first = m_transactions.size();
            const auto last = m_transactions.size() + transactions.size() - 1;
            beginInsertRows(QModelIndex(), first, last);
            m_transactions.append(transactions);
            endInsertRows();
        }

        m_get_transactions->deleteLater();
        m_get_transactions = nullptr;

        if (transactions.size() == count) {
            fetch(offset + count, count);
        }
    });
    m_account->context()->dispatcher()->add("transaction list model", m_get_transactions);
}

QHash<int, QByteArray> TransactionListModel::roleNames() const
{
    return {
        { Qt::UserRole, "transaction" },
        { Qt::UserRole + 1, "date" },
    };
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
    if (index.row() >= 0 || index.row() < m_transactions.size()) {
        auto transaction = m_transactions.at(index.row());
        if (role == Qt::UserRole) {
            return QVariant::fromValue(transaction);
        } else if (role == Qt::UserRole + 1) {
            const auto now = QDateTime::currentDateTime();
            const auto created_at = QDateTime::fromMSecsSinceEpoch(transaction->data().value("created_at_ts").toDouble() / 1000);
            auto date = created_at.date();
            const auto diff = created_at.daysTo(now);
            if (diff > 365) return QString("%1").arg(date.year());
            if (diff > 30) return QString("%2/%1").arg(date.year()).arg(date.month());
            return QString(); // QString("%3/%2/%1").arg(date.year()).arg(date.month()).arg(date.day());
        }
    }
    return {};
}

void TransactionListModel::reload()
{
    if (!m_account) return;
    m_reload_timer->start();
}

void TransactionListModel::handleBlockEvent(const QJsonObject &event)
{
    if (m_has_unconfirmed) reload();
}

void TransactionListModel::handleTransactionEvent(const QJsonObject &event)
{
    reload();
}

TransactionFilterProxyModel::TransactionFilterProxyModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

void TransactionFilterProxyModel::setModel(TransactionListModel* model)
{
    if (m_model == model) return;
    m_model = model;
    emit modelChanged();
    setSourceModel(m_model);
}

void TransactionFilterProxyModel::setFilter(const QString& filter)
{
    if (m_filter == filter) return;
    m_filter = filter;
    emit filterChanged();
    if (!m_filter.isEmpty()) m_model->fetchMore({});
    invalidateRowsFilter();
}

int TransactionFilterProxyModel::maxRowCount() const
{
    return m_max_row_count;
}

void TransactionFilterProxyModel::setMaxRowCount(int max_row_count)
{
    m_max_row_count = max_row_count;
    emit maxRowCountChanged();
}

bool TransactionFilterProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    if (m_max_row_count >= 0 && source_row >= m_max_row_count) return false;
    if (m_filter.isEmpty()) return true;
    auto transaction = m_model->index(source_row, 0, source_parent).data(Qt::UserRole).value<Transaction*>();
    if (transaction->hash().contains(m_filter, Qt::CaseInsensitive)) return true;
    if (transaction->memo().contains(m_filter, Qt::CaseInsensitive)) return true;
    return false;
}
