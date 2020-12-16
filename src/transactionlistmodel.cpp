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
        fetch(0, 2);
        return;
    }
}

void TransactionListModel::fetch(int offset, int count)
{
    auto handler = new GetTransactionsHandler(m_account->pointer(), offset, count, m_account->wallet());

    QObject::connect(handler, &Handler::done, this, [this, handler] {
        // ignore handler result if no longer relevant
        if (handler != m_handler) return;
        QJsonArray transactions = handler->result().value("result").toObject().value("transactions").toArray();
        QVector<Transaction*> txs;
        int index = -1;
        for (auto data : transactions) {
            Transaction* transaction = m_account->getOrCreateTransaction(data.toObject());
            index = m_transactions.indexOf(transaction);
            if (index >= 0) break;
            txs.append(transaction);
        }
        if (index < 0) {
            beginInsertRows(QModelIndex(), m_transactions.size(), m_transactions.size() + txs.size() - 1);
            m_transactions.append(txs);
            endInsertRows();
        } else {
            beginInsertRows(QModelIndex(), index, index + txs.size() - 1);
            while (!txs.empty()) {
                m_transactions.insert(index++, txs.takeFirst());
            }
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
    fetch(m_transactions.size(), 10);
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
    m_handler = nullptr;
    beginResetModel();
    m_transactions.clear();
    endResetModel();
}
