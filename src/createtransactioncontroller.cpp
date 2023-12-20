#include "account.h"
#include "asset.h"
#include "context.h"
#include "createtransactioncontroller.h"
#include "session.h"
#include "network.h"
#include "task.h"

#include <gdk.h>
#include <ga.h>

Recipient::Recipient(QObject* parent)
    : QObject(parent)
{
}

void Recipient::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
}

void Recipient::setAddress(const QString& address)
{
    if (m_address == address) return;
    m_address = address;
    emit addressChanged();
}

void Recipient::setAmount(const QString& amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    emit amountChanged();
}

void Recipient::setGreedy(bool greedy)
{
    if (m_greedy == greedy) return;
    m_greedy = greedy;
    emit greedyChanged();
}

CreateTransactionController::CreateTransactionController(QObject* parent)
    : Controller(parent)
    , m_recipient(new Recipient(this))
{
}

void CreateTransactionController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    m_utxos = QJsonValue::Null;
}

void CreateTransactionController::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
    m_recipient->setAsset(asset);
}

void CreateTransactionController::setCoins(const QVariantList& coins)
{
    if (m_coins == coins) return;
    m_coins = coins;
    emit coinsChanged();
    invalidate();
}

void CreateTransactionController::setFeeRate(int fee_rate)
{
    if (m_fee_rate == fee_rate) return;
    m_fee_rate = fee_rate;
    emit feeRateChanged();
    invalidate();
}

void CreateTransactionController::invalidate()
{
    if (m_update_timer != -1) killTimer(m_update_timer);
    m_update_timer = startTimer(5);
}

void CreateTransactionController::update()
{
    if (m_context && m_account) {
        auto context = m_account->context();
        auto dispatcher = context->dispatcher();

        if (m_utxos.isNull()) {
            auto task = new GetUnspentOutputsTask(0, false, m_account);
            connect(task, &Task::finished, this, [=] {
                m_utxos = task->unspentOutputs();
                task->deleteLater();
                update();
            });
            dispatcher->add(task);
        } else {
            auto session = m_account->session();

            QJsonObject addressee;
            addressee.insert("address", m_recipient->address());
            addressee.insert("satoshi", m_recipient->amount().toLongLong());
            addressee.insert("is_greedy", m_recipient->isGreedy());
            if (session->network()->isLiquid() && m_recipient->asset()) {
                addressee.insert("asset_id", m_recipient->asset()->id());
            }

            QJsonArray addressees;
            addressees.append(addressee);

            QJsonObject details = {{"utxos", m_utxos}, {"addressees", addressees}};
            if (m_fee_rate > 0) details["fee_rate"] = m_fee_rate;
            auto task = new CreateTransactionTask(details, session);
            connect(task, &CreateTransactionTask::finished, this, [=] {
                setTransaction(task->transaction());
                task->deleteLater();
            });
            connect(task, &CreateTransactionTask::failed, this, [=](const QString& error) {
                qDebug() << error;
                task->deleteLater();
            });
            dispatcher->add(task);
        }
    }
}

void CreateTransactionController::timerEvent(QTimerEvent* event)
{
    Controller::timerEvent(event);
    if (event->timerId() == m_update_timer) {
        killTimer(m_update_timer);
        m_update_timer = -1;
        update();
    }
}

void CreateTransactionController::setTransaction(const QJsonObject& transaction)
{
    m_transaction = transaction;
    emit transactionChanged();
    const auto addressees = m_transaction.value("addressees").toArray();
    if (addressees.size() > 0) {
        const auto addressee = addressees.at(0).toObject();
        bool is_greedy = addressee.value("is_greedy").toBool();
        qint64 satoshi = addressee.value("satoshi").toInteger();
        if (is_greedy) {
            m_recipient->setAmount(QString::number(satoshi));
        }
    }
}
