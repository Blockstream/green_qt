#include "bumpfeecontroller.h"

#include <gdk.h>

#include "account.h"
#include "context.h"
#include "task.h"
#include "transaction.h"
#include "wallet.h"

BumpFeeController::BumpFeeController(QObject* parent)
    : AccountController(parent)
{
}

void BumpFeeController::setFeeRate(int fee_rate)
{
    if (m_fee_rate == fee_rate) return;
    m_fee_rate = fee_rate;
    emit changed();
    create();
}

void BumpFeeController::bumpFee()
{
    Q_ASSERT(!m_tx.isEmpty());
    Q_ASSERT(m_tx.value("error").toString().isEmpty());

    const auto wallet = context()->wallet();

    auto sign = new SignTransactionTask(m_tx, m_context);
    auto send = new SendTransactionTask(m_context);
    auto load_config = new LoadTwoFactorConfigTask(m_context);

    sign->then(send);
    send->then(load_config);

    connect(sign, &Task::finished, this, [=] {
        auto details = sign->result().value("result").toObject();
        send->setDetails(details);
    });

    connect(send, &Task::finished, this, [=] {
        const auto transaction = m_account->getOrCreateTransaction(send->result().value("result").toObject());
        setSignedTransaction(transaction);
    });

    connect(send, &Task::finished, this, &BumpFeeController::finished);

    auto group = new TaskGroup(this);
    group->add(sign);
    group->add(send);
    group->add(load_config);
    m_dispatcher->add(group);
}

void BumpFeeController::setTransaction(Transaction* transaction)
{
    if (m_transaction == transaction) return;
    m_transaction = transaction;
    emit transactionChanged();
    create();
}

void BumpFeeController::create()
{
    if (!account()) return;
    if (!m_context) return;
    const auto wallet = m_context->wallet();
    if (!wallet) return;
    if (!m_transaction) return;
    int req = ++m_req;
    if (m_create_task) return;
    auto a = account();

    if (m_get_unspent_outputs) return;
    if (m_utxos.isNull()) {
        m_get_unspent_outputs = new GetUnspentOutputsTask(1, false, a->pointer(), m_context);
        connect(m_get_unspent_outputs, &Task::finished, this, [=] {
            m_utxos = m_get_unspent_outputs->unspentOutputs();
            m_get_unspent_outputs = nullptr;
            create();
        });
        m_dispatcher->add(m_get_unspent_outputs);
        return;
    }

    QJsonObject details{
        { "subaccount", static_cast<qint64>(a->pointer()) },
        { "fee_rate", m_fee_rate },
        { "utxos", m_utxos },
        { "previous_transaction", m_transaction->data() }
    };

    m_create_task = new CreateTransactionTask(details, m_context);
    connect(m_create_task, &CreateTransactionTask::transaction, this, [=](const QJsonObject& transaction) {
        if (m_req == req) {
            m_tx = transaction;
            emit txChanged(m_tx);
            m_req = 0;
            m_create_task = nullptr;
        } else {
            m_create_task = nullptr;
            create();
        }
    });
    m_dispatcher->add(m_create_task);
}

void BumpFeeController::setSignedTransaction(Transaction* signed_transaction)
{
    if (m_signed_transaction == signed_transaction) return;
    m_signed_transaction = signed_transaction;
    emit signedTransactionChanged();
}
