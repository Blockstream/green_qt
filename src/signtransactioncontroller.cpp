#include "account.h"
#include "network.h"
#include "signtransactioncontroller.h"
#include "task.h"

SignTransactionController::SignTransactionController(QObject* parent)
    : Controller(parent)
{
}

void SignTransactionController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
}

void SignTransactionController::setTransaction(const QJsonObject& transaction)
{
    if (m_transaction == transaction) return;
    m_transaction = transaction;
    emit transactionChanged();
}

void SignTransactionController::setMemo(const QString& memo)
{
    if (m_memo == memo) return;
    m_memo = memo;
    emit memoChanged();
}

void SignTransactionController::sign()
{
    setMonitor(new TaskGroupMonitor(this));

    auto transaction = m_transaction;
    transaction.insert("memo", m_memo);

    const auto session = m_account->session();
    const auto network = m_account->network();

    TaskGroup* group = new TaskGroup(this);

    auto sign = new SignTransactionTask(session);
    auto send = new SendTransactionTask(session);

    if (network->isLiquid()) {
        auto blind = new BlindTransactionTask(transaction, session);
        blind->then(sign);

        connect(blind, &Task::finished, this, [=] {
            auto details = blind->result().value("result").toObject();
            sign->setDetails(details);
        });

        group->add(blind);
    } else {
        sign->setDetails(transaction);
    }

    sign->then(send);

    group->add(sign);
    group->add(send);
    dispatcher()->add(group);
    monitor()->add(group);

    m_error.clear();

    connect(sign, &Task::failed, this, [=](const QString& error) {
        m_error.append(error);
    });
    connect(send, &Task::failed, this, [=](const QString& error) {
        m_error.append(error);
    });
    connect(group, &TaskGroup::failed, this, [=] {
        emit failed(m_error);
    });
    connect(sign, &Task::finished, this, [=] {
        auto details = sign->result().value("result").toObject();
        send->setDetails(details);
    });
    connect(send, &Task::finished, this, [=] {
        auto transaction = m_account->getOrCreateTransaction(send->transaction());
        emit transactionCompleted(transaction);
    });
}


