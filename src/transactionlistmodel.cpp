#include "account.h"
#include "resolver.h"
#include "transaction.h"
#include "transactionlistmodel.h"
#include "handlers/gettransactionshandler.h"
#include <QDebug>

TransactionListModel::TransactionListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_reload_timer(new QTimer(this))
{
    m_reload_timer->setSingleShot(true);
    m_reload_timer->setInterval(200);
    connect(m_reload_timer, &QTimer::timeout, [this] {
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

void TransactionListModel::fetch(bool reset, int offset, int count)
{
    auto handler = new GetTransactionsHandler(m_account->pointer(), offset, count, m_account->wallet());

    QObject::connect(handler, &Handler::done, this, [this, reset, handler] {
        handler->deleteLater();
        m_handler = nullptr;
        emit fetchingChanged(false);
        // instantiate missing transactions
        QVector<Transaction*> transactions;
        for (QJsonValue data : handler->transactions()) {
            transactions.append(m_account->getOrCreateTransaction(data.toObject()));
        }
        if (reset) {
            // just swap rows instead of incremental update
            // this happens after a bump fee for instance
            beginResetModel();
            m_transactions = transactions;
            endResetModel();
        } else {
            // new page of transactions, just append to existing transaction
            beginInsertRows(QModelIndex(), m_transactions.size(), m_transactions.size() + transactions.size() - 1);
            m_transactions.append(transactions);
            endInsertRows();
        }
    });

    connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
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
