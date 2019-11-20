#include "sendtransactioncontroller.h"
#include "../account.h"
#include "../wallet.h"
#include "../json.h"
#include <QDebug>

SendTransactionController::SendTransactionController(QObject* parent)
    : AccountController(parent)
{

}

QString SendTransactionController::address() const
{
    return m_address;
}

void SendTransactionController::setAddress(const QString &address)
{
    if (m_address == address)
        return;

    m_address = address;
    emit addressChanged(m_address);
    create();
}

bool SendTransactionController::sendAll() const
{
    return m_send_all;
}

void SendTransactionController::setSendAll(bool send_all)
{
    if (m_send_all == send_all) return;
    m_send_all = send_all;
    emit sendAllChanged(m_send_all);
    create();
}

QString SendTransactionController::amount() const
{
    return m_amount;
}

void SendTransactionController::setAmount(const QString& amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    emit amountChanged(m_amount);
    create();
}

qint64 SendTransactionController::feeRate() const
{
    return m_fee_rate;
}

void SendTransactionController::setFeeRate(qint64 fee_rate)
{
    if (m_fee_rate == fee_rate) return;
    m_fee_rate = fee_rate;
    emit feeRateChanged(m_fee_rate);
    create();
}

QJsonObject SendTransactionController::transaction() const
{
    return m_transaction;
}

void SendTransactionController::create()
{
    if (m_address == nullptr) return;

    if (!m_fee_rate) {
        m_fee_rate = static_cast<qint64>(m_wallet->settings().value("required_num_blocks").toInt());
    }

    QLocale locale;
    bool ok;
    qint64 amount = static_cast<qint64>(locale.toDouble(m_amount, &ok) * 100000000);
    if (!ok) return;

    QJsonObject address{
        { "address", m_address },
        { "satoshi", amount }
    };

    auto details = Json::fromObject({
        { "subaccount", static_cast<qint64>(m_account->m_pointer) },
        { "fee_rate", m_fee_rate },
        { "send_all", m_send_all },
        { "addressees", QJsonArray{address}}
    });

    incrementBusy();

    QMetaObject::invokeMethod(m_wallet->m_context, [this, details] {
        GA_json* tx1;
        int res = GA_create_transaction(m_wallet->m_session, details, &tx1);
        Q_ASSERT(res == GA_OK);
        m_transaction = Json::toObject(tx1);
        GA_destroy_json(details);
        GA_destroy_json(tx1);

        qDebug() << m_transaction;

        emit transactionChanged();

        decrementBusy();
    });
}

void SendTransactionController::send()
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        qDebug("SENDING");
        GA_session* session = m_wallet->m_session;
        GA_json* tx1 = Json::fromObject(m_transaction);

        int res = GA_sign_transaction(session, tx1, &m_auth_handler);
        Q_ASSERT(res == GA_OK);

        GA_json* tx2;
        process(&tx2);
        GA_destroy_auth_handler(m_auth_handler);
        GA_destroy_json(tx1);

        res = GA_send_transaction(session, tx2, &m_auth_handler);
        Q_ASSERT(res == GA_OK);

//        GA_json* tx3;
        process(nullptr);
        //GA_destroy_auth_handler(m_);
        //GA_destroy_json(tx2);
    });

    //GA_json* tx3;
    //process();
    //GA::process_auth(call, &tx3);
}
