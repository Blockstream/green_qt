#include "bumpfeecontroller.h"
#include "account.h"
#include "asset.h"
#include "balance.h"
#include "handlers/createtransactionhandler.h"
#include "handlers/sendtransactionhandler.h"
#include "handlers/signtransactionhandler.h"
#include "json.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"

#include <gdk.h>

#include <QDebug>

BumpFeeController::BumpFeeController(QObject* parent)
    : AccountController(parent)
{
}

Transaction* BumpFeeController::transaction()
{
    QQmlContext* context = qmlContext(this);
    if (!context) return nullptr;
    auto transaction = context->contextProperty("transaction");
    if (transaction.isNull()) return nullptr;
    return qobject_cast<Transaction*>(transaction.value<QObject*>());
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
           send->deleteLater();
           wallet()->updateConfig();
           emit finished();
        });
        exec(send);
    });
    exec(sign);
}

void BumpFeeController::create()
{
    if (!account()) return;
    if (!wallet()) return;
    if (!transaction()) return;
    int req = ++m_req;
    if (m_create_handler) return;
    auto t = transaction();
    auto a = account();

    QJsonObject details{
        { "subaccount", static_cast<qint64>(a->pointer()) },
        { "fee_rate", m_fee_rate },
        { "previous_transaction", t->data() }
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
