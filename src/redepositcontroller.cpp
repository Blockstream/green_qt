#include "account.h"
#include "asset.h"
#include "context.h"
#include "convert.h"
#include "redepositcontroller.h"
#include "network.h"
#include "output.h"
#include "session.h"
#include "task.h"
#include "transaction.h"

#include <gdk.h>
#include <ga.h>

RedepositController::RedepositController(QObject* parent)
    : Controller(parent)
{
}

void RedepositController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    m_utxos = QJsonValue::Null;
    invalidate();
}

void RedepositController::setCoins(const QVariantList& coins)
{
    if (m_coins == coins) return;
    m_coins = coins;
    emit coinsChanged();
    invalidate();
}

void RedepositController::setFeeRate(int fee_rate)
{
    if (m_fee_rate == fee_rate) return;
    m_fee_rate = fee_rate;
    emit feeRateChanged();
    invalidate();
}

void RedepositController::invalidate()
{
    if (m_update_timer != -1) killTimer(m_update_timer);
    m_update_timer = startTimer(5);
}

void RedepositController::update()
{
    if (m_context && m_account) {
        auto context = m_account->context();
        auto dispatcher = context->dispatcher();

        if (m_utxos.isNull()) {
            auto task = new GetUnspentOutputsTask(0, false, m_account);
            connect(task, &Task::finished, this, [=] {
                m_utxos = task->unspentOutputs();
                emit utxosChanged();
                task->deleteLater();
                invalidate();
            });
            dispatcher->add(task);
            return;
        }

        auto session = m_account->session();

        QJsonObject details = m_transaction;
        if (m_coins.isEmpty()) {
            details["utxos"] = m_utxos;
        }
        if (m_fee_rate > 0) {
            details["fee_rate"] = m_fee_rate;
        } else {
            const auto estimates = gdk::get_fee_estimates(session->m_session);
            if (estimates.size() > 24) {
                details["fee_rate"] = estimates.at(24);
            }
        }
        auto task = new CreateRedepositTransactionTask(details, session);
        connect(task, &CreateRedepositTransactionTask::finished, this, [=] {
            setTransaction(task->transaction());
            task->deleteLater();
        });
        connect(task, &CreateRedepositTransactionTask::failed, this, [=](const QString& error) {
            setTransaction({{ "error", task->error() }});
            task->deleteLater();
        });
        dispatcher->add(task);
    }
}

void RedepositController::timerEvent(QTimerEvent* event)
{
    Controller::timerEvent(event);
    if (event->timerId() == m_update_timer) {
        killTimer(m_update_timer);
        m_update_timer = -1;
        update();
    }
}

void RedepositController::setTransaction(const QJsonObject& transaction)
{
    m_transaction = transaction;
    emit transactionChanged();
    const auto error = m_transaction.value("error").toString();
    if (!error.isEmpty()) {
        qDebug() << Q_FUNC_INFO << error;
    }
}
