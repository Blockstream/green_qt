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
}

qint64 SendTransactionController::amount() const
{
    return m_amount;
}

void SendTransactionController::setAmount(qint64 amount)
{
    if (m_amount == amount)
        return;

    m_amount = amount;
    emit amountChanged(m_amount);
}

void SendTransactionController::send()
{
    qDebug("SENDING 1");
    qDebug() << m_wallet;
    qDebug() << m_account;
    qDebug() << m_wallet->m_context;
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        auto details = Json::fromObject({
            { "subaccount", static_cast<qint64>(m_account->m_pointer) },
            { "addressees", QJsonArray{
                QJsonObject{
                    { "address", m_address },
                    { "satoshi", m_amount }
                }
            }}
        });
        qDebug("SENDING 2");
        GA_session* session = m_wallet->m_session;

        GA_json* tx1;
        int res = GA_create_transaction(session, details, &tx1);
        Q_ASSERT(res == GA_OK);
        GA_destroy_json(details);

        res = GA_sign_transaction(session, tx1, &m_auth_handler);
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
