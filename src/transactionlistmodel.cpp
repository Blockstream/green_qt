#include "account.h"
#include "resolver.h"
#include "transaction.h"
#include "transactionlistmodel.h"
#include "handlers/gettransactionshandler.h"
#include <QDebug>

TransactionListModel::TransactionListModel(QObject* parent)
    : QAbstractListModel(parent)
{    
}

TransactionListModel::~TransactionListModel()
{

}

void TransactionListModel::setAccount(Account *account)
{
    if (m_account) {
        beginResetModel();
        m_handler = nullptr;
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
}

void TransactionListModel::fetch(int offset, int count)
{
    auto handler = new GetTransactionsHandler(m_account->pointer(), offset, count, m_account->wallet());

    QObject::connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();
        // instantiate missing transactions
        QVector<Transaction*> transactions;
        for (QJsonValue data : handler->transactions()) {
            transactions.append(m_account->getOrCreateTransaction(data.toObject()));
        }
        if (m_needs_reset) {
            // just swap rows instead of incremental update
            // this happens after a bump fee for instance
            m_needs_reset = false;
            beginResetModel();
            m_transactions = transactions;
            endResetModel();
        } else {
            // new page of transactions, just append to existing transaction
            beginInsertRows(QModelIndex(), m_transactions.size(), m_transactions.size() + transactions.size() - 1);
            m_transactions.append(transactions);
            endInsertRows();
        }
        m_handler = nullptr;
        emit fetchingChanged(false);
    });

    connect(handler, &Handler::resolver, [](Resolver* resolver) {
        resolver->resolve();
    });

    handler->exec();
    m_handler = handler;
    emit fetchingChanged(true);
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
    if (m_handler) return false;
    return true;
}

void TransactionListModel::fetchMore(const QModelIndex &parent)
{
    Q_ASSERT(!parent.parent().isValid());
    if (!m_account) return;
    if (m_handler) return;
    fetch(m_transactions.size(), 20);
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
    // TODO: cancel active handler
    m_handler = nullptr;
    m_needs_reset = true;
    fetch(0, 20);
}
