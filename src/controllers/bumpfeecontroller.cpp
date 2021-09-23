#include "bumpfeecontroller.h"
#include "account.h"
#include "asset.h"
#include "balance.h"
#include "handlers/createtransactionhandler.h"
#include "handlers/getunspentoutputshandler.h"
#include "handlers/sendtransactionhandler.h"
#include "handlers/signtransactionhandler.h"
#include "json.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"

#include <gdk.h>

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
    auto sign = new SignTransactionHandler(wallet(), m_tx);
    connect(sign, &Handler::done, this, [this, sign] {
        auto details = sign->result().value("result").toObject();
        auto send = new SendTransactionHandler(wallet(), details);
        connect(send, &Handler::done, this, [this, send] {
            setSignedTransaction(m_account->getOrCreateTransaction(send->result().value("result").toObject()));
            send->deleteLater();
            wallet()->updateConfig();
            emit finished();
        });
        exec(send);
    });
    exec(sign);
}

void BumpFeeController::setTransaction(Transaction *transaction)
{
    if (m_transaction == transaction) return;
    m_transaction = transaction;
    emit transactionChanged(m_transaction);
    create();
}

void BumpFeeController::create()
{
    if (!account()) return;
    if (!wallet()) return;
    if (!m_transaction) return;
    int req = ++m_req;
    if (m_create_handler) return;
    auto a = account();

    if (m_get_unspent_outputs_handler) return;
    if (m_utxos.isNull()) {
        auto handler = new GetUnspentOutputsHandler(1, true, a);
        connect(handler, &Handler::finished, this, [this, handler] {
            m_utxos = handler->unspentOutputs();
            m_get_unspent_outputs_handler = nullptr;
            create();
            handler->deleteLater();
        });
        connect(handler, &Handler::error, this, [&] {
            handler->deleteLater();
        });
        m_get_unspent_outputs_handler = handler;
        handler->exec();
        return;
    }

    QJsonObject details{
        { "subaccount", static_cast<qint64>(a->pointer()) },
        { "fee_rate", m_fee_rate },
        { "utxos", m_utxos },
        { "previous_transaction", m_transaction->data() }
    };

    m_create_handler = new CreateTransactionHandler(wallet(), details);
    connect(m_create_handler, &Handler::done, this, [this, req] {
        if (m_req == req) {
            m_tx = m_create_handler->result().value("result").toObject();
            emit txChanged(m_tx);
            m_req = 0;
            m_create_handler = nullptr;
        } else {
            m_create_handler = nullptr;
            create();
        }
    });
    exec(m_create_handler);
}

void BumpFeeController::setSignedTransaction(Transaction *signed_transaction)
{
    if (m_signed_transaction==signed_transaction) return;
    m_signed_transaction = signed_transaction;
    emit signedTransactionChanged(m_signed_transaction);
}
