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

    m_get_transactions_activity->exec();
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

