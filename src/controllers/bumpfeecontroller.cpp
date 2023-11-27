#include "bumpfeecontroller.h"

#include <gdk.h>

#include "account.h"
#include "context.h"
#include "network.h"
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

    auto group = new TaskGroup(this);

    const auto wallet = context()->wallet();

    auto network = m_transaction->account()->network();
    auto session = context()->getOrCreateSession(network);
    auto sign = new SignTransactionTask(session);
    auto send = new SendTransactionTask(session);
    auto load_config = new LoadTwoFactorConfigTask(session);

    if (network->isLiquid()) {
        auto blind = new BlindTransactionTask(m_tx, session);
        blind->then(sign);

        connect(blind, &Task::finished, this, [=] {
            auto details = blind->result().value("result").toObject();
            sign->setDetails(details);
        });

        group->add(blind);
    } else {
        sign->setDetails(m_tx);
    }

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

    group->add(sign);
    group->add(send);
    group->add(load_config);
    dispatcher()->add(group);
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
    const auto network = m_transaction->account()->network();
    int req = ++m_req;
    if (m_create_task) return;
    auto a = account();

    if (m_get_unspent_outputs) return;
    if (m_utxos.isNull()) {
        m_get_unspent_outputs = new GetUnspentOutputsTask(1, false, a);
        connect(m_get_unspent_outputs, &Task::finished, this, [=] {
            m_utxos = m_get_unspent_outputs->unspentOutputs();
            m_get_unspent_outputs = nullptr;
            create();
        });
        dispatcher()->add(m_get_unspent_outputs);
        return;
    }

    QJsonObject details{
        { "subaccount", static_cast<qint64>(a->pointer()) },
        { "fee_rate", m_fee_rate },
        { "utxos", m_utxos },
        { "previous_transaction", m_transaction->data() }
    };

    auto session = m_context->getOrCreateSession(network);
    m_create_task = new CreateTransactionTask(details, session);
    connect(m_create_task, &CreateTransactionTask::finished, this, [=]() {
        if (m_req == req) {
            m_tx = m_create_task->transaction();
            emit txChanged(m_tx);
            m_req = 0;
            m_create_task = nullptr;
        } else {
            m_create_task = nullptr;
            create();
        }
    });
    dispatcher()->add(m_create_task);
}

void BumpFeeController::setSignedTransaction(Transaction* signed_transaction)
{
    if (m_signed_transaction == signed_transaction) return;
    m_signed_transaction = signed_transaction;
    emit signedTransactionChanged();
}
