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
    , m_recipient(new Recipient(this))
{
    connect(m_recipient, &Recipient::changed, this, &RedepositController::invalidate);
}

void RedepositController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    m_recipient->convert()->setAccount(account);
    m_utxos = QJsonValue::Null;
    invalidate();
}

void RedepositController::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
    m_recipient->convert()->setAsset(asset);
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
            const auto block_height = m_account->session()->blockHeight();
            task->setExpiredAt(block_height);
            connect(task, &Task::finished, this, [=] {
                m_utxos = task->unspentOutputs();
                emit utxosChanged();
                task->deleteLater();
                update();
            });
            dispatcher->add(task);
            return;
        }

        if (m_recipient->address().trimmed().isEmpty()) {
            auto task = new GetReceiveAddressTask(m_account);
            connect(task, &Task::finished, this, [=] {
                const auto result = task->result().value("result").toObject();
                const auto address = result.value("address").toString();
                m_recipient->setAddress(address);
                m_recipient->setGreedy(true);
                task->deleteLater();
                update();
            });
            dispatcher->add(task);
            setTransaction({});
            return;
        }

        auto session = m_account->session();

        QJsonObject details;
        if (m_coins.isEmpty()) {
            details["utxos"] = m_utxos;
        } else {
            qDebug() << "use coins";
            QJsonArray utxos;
            for (auto coin : m_coins) {
                auto output = coin.value<Output*>();
                utxos.append(output->data());
            }
            qDebug() << utxos;
            details["utxos"] = QJsonObject{{ m_asset->id(), utxos }};
        }

        QJsonObject addressee;
        addressee.insert("address", m_recipient->address().trimmed());
        addressee.insert("satoshi", m_recipient->convert()->satoshi().toLongLong());
        addressee.insert("is_greedy", !m_recipient->address().contains("amount") && m_recipient->isGreedy());
        if (session->network()->isLiquid() && m_recipient->convert()->asset()) {
            addressee.insert("asset_id", m_recipient->convert()->asset()->id());
        }
        QJsonArray addressees;
        addressees.append(addressee);
        details["addressees"] = addressees;

        if (m_fee_rate > 0) details["fee_rate"] = m_fee_rate;
        auto task = new CreateTransactionTask(details, session);
        connect(task, &CreateTransactionTask::finished, this, [=] {
            setTransaction(task->transaction());
            task->deleteLater();
        });
        connect(task, &CreateTransactionTask::failed, this, [=](const QString& error) {
            qDebug() << error;
            task->deleteLater();
            setTransaction({});
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
    const auto addressees = m_transaction.value("addressees").toArray();
    if (addressees.size() > 0) {
        const auto addressee = addressees.at(0).toObject();
        const auto bip21_params = addressee.value("bip21-params").toObject();
        if (addressee.contains("bip21-params")) {
        if (bip21_params.contains("assetid")) {
            const auto asset_id = bip21_params.value("assetid").toString();
            const auto asset = m_context->getOrCreateAsset(asset_id);
            setAsset(asset);
        }
        const auto address = addressee.value("address").toString();
        if (!address.isEmpty()) {
            m_recipient->setAddress(address);
        }
        if (bip21_params.contains("amount")) {
            m_recipient->setGreedy(false);
            const auto satoshi = addressee.value("satoshi").toInteger();
            m_recipient->convert()->setInput({{ "satoshi", satoshi }});
        }
        } else if (addressee.value("is_greedy").toBool()) {
            const auto satoshi = addressee.value("satoshi").toInteger();
            m_recipient->convert()->setInput({{ "satoshi", satoshi }});
        }
    }
}
