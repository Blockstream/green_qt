#include "sendtransactioncontroller.h"
#include "../account.h"
#include "../wallet.h"
#include "../json.h"
#include <QDebug>

SendTransactionController::SendTransactionController(QObject* parent)
    : AccountController(parent)
{

}

bool SendTransactionController::isValid() const
{
    return m_valid;
}

void SendTransactionController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged(m_valid);
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
        m_fee_rate = static_cast<qint64>(wallet()->settings().value("required_num_blocks").toInt());
    }

    QLocale locale;
    bool ok;
    qint64 amount = static_cast<qint64>(locale.toDouble(m_amount, &ok) * 100000000);
    if (!ok) return;

    incrementBusy();

    QMetaObject::invokeMethod(wallet()->m_context, [this, amount] {
        QJsonObject address{
            { "address", m_address },
            { "satoshi", amount }
        };

        auto details = Json::fromObject({
            { "subaccount", static_cast<qint64>(account()->m_pointer) },
            { "fee_rate", m_fee_rate },
            { "send_all", m_send_all },
            { "addressees", QJsonArray{address}}
        });

        m_transaction = GA::process_auth([&] (GA_auth_handler** call) {
            int err = GA_create_transaction(wallet()->m_session, details, call);
            Q_ASSERT(err == GA_OK);
        });

        int err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);

        emit transactionChanged();

        decrementBusy();
    });
}

void SendTransactionController::send()
{
    QMetaObject::invokeMethod(wallet()->m_context, [this] {
        auto transaction = GA::process_auth([&] (GA_auth_handler** call) {
            GA_json* details = Json::fromObject(m_transaction);

            int err = GA_sign_transaction(wallet()->m_session, details, call);
            Q_ASSERT(err == GA_OK);

            err = GA_destroy_json(details);
            Q_ASSERT(err == GA_OK);
        });

        GA::process_auth([&] (GA_auth_handler** call) {
            GA_json* details = Json::fromObject(transaction);

            int err = GA_send_transaction(wallet()->m_session, details, call);
            Q_ASSERT(err == GA_OK);

            err = GA_destroy_json(details);
            Q_ASSERT(err == GA_OK);
        });
    });
}
