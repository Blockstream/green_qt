#include "account.h"
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

void SignTransactionController::sign()
{
    setMonitor(new TaskGroupMonitor(this));

    auto transaction = m_transaction;

    TaskGroup* group = new TaskGroup(this);

    auto sign = new SignTransactionTask(m_account->session());
    auto send = new SendTransactionTask(m_account->session());

    sign->setDetails(transaction);
    sign->then(send);

    group->add(sign);
    group->add(send);
    dispatcher()->add(group);
    monitor()->add(group);

    connect(sign, &Task::finished, this, [=] {
        auto details = sign->result().value("result").toObject();
        send->setDetails(details);
    });
    connect(send, &Task::finished, this, [=] {
        auto transaction = m_account->getOrCreateTransaction(send->transaction());
        emit transactionCompleted(transaction);
    });
}


