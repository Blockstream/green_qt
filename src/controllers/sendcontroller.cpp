#include "account.h"
#include "asset.h"
#include "balance.h"
#include "context.h"
#include "json.h"
#include "network.h"
#include "sendcontroller.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

SendController::SendController(QObject* parent)
    : AccountController(parent)
{
    connect(this, &SendController::accountChanged, this, &SendController::create);
}

SendController::~SendController()
{
    if (account()) {
        emit account()->addressGenerated();
    }
}

bool SendController::isValid() const
{
    return m_valid;
}

Balance* SendController::balance() const
{
    return m_balance;
}

void SendController::setBalance(Balance* balance)
{
    if (m_balance == balance) return;
    m_balance = balance;
    m_amount.clear();
    m_fiat_amount.clear();
    update();
}

void SendController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit changed();
}

QString SendController::address() const
{
    return m_address;
}

void SendController::setAddress(const QString& address)
{
    if (m_address == address) return;
    m_address = address;
    emit changed();
    create();
}

bool SendController::sendAll() const
{
    return m_send_all;
}

void SendController::setSendAll(bool send_all)
{
    if (m_send_all == send_all) return;
    m_send_all = send_all;
    m_amount.clear();
    m_fiat_amount.clear();
    update();
}

void SendController::setAmount(const QString& amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    m_fiat_amount.clear();
    update();
}

void SendController::setFiatAmount(const QString& fiat_amount)
{
    Q_ASSERT(hasFiatRate());
    if (m_fiat_amount == fiat_amount) return;
    m_fiat_amount = fiat_amount;
    m_amount.clear();
    update();
}

QString SendController::memo() const
{
    return m_memo;
}

void SendController::setMemo(const QString &memo)
{
    if (m_memo == memo) return;
    Q_ASSERT(memo.length() <= 1024);
    m_memo = memo;
    emit changed();
}

qint64 SendController::feeRate() const
{
    return m_fee_rate;
}

void SendController::setFeeRate(qint64 fee_rate)
{
    if (m_fee_rate == fee_rate) return;
    m_fee_rate = fee_rate;
    emit changed();
    create();
}

bool SendController::hasFiatRate() const
{
    if (!m_account) return false;
    if (!m_account->network()->isLiquid()) return true;
    if (m_balance && m_balance->asset()->isLBTC()) return true;
    return false;
}

QJsonObject SendController::transaction() const
{
    return m_transaction;
}

void SendController::update()
{
    if (!m_account) return;
    if (!m_context) return;
    const auto session = m_account->session();
    const bool is_liquid = m_account->network()->isLiquid();
    if (hasFiatRate()) {
        if (!m_send_all) {
            auto unit = session->unit();
            unit = unit == "\u00B5BTC" ? "ubtc" : unit.toLower();
            QJsonObject convert;

            if (!m_amount.isEmpty()) {
                Q_ASSERT(m_fiat_amount.isEmpty());
                auto amount = m_amount;
                amount.replace(',', '.');
                convert.insert(unit, amount);
            } else if (!m_fiat_amount.isEmpty()) {
                Q_ASSERT(m_amount.isEmpty());
                auto fiat = m_fiat_amount;
                fiat.replace(',', '.');
                convert.insert("fiat", fiat);
            }

            const auto res = m_context->wallet()->convert(convert);
            m_effective_amount = res.value(unit).toString();
            m_effective_fiat_amount = res.value("fiat").isNull() ? "n/a" : res.value("fiat").toString();
        }
    } else {
        Q_ASSERT(is_liquid);
        if (m_send_all) {
            if (m_balance) {
                m_effective_amount = m_balance->asset()->formatAmount(m_balance->amount(), /* include_ticker = */ false);
            }
        } else {
            m_effective_amount = m_amount;
        }
        m_effective_fiat_amount.clear();
    }
    emit changed();
    create();
}

void SendController::create()
{
    if (!m_context) return;
    if (!m_account) return;

    const auto wallet = m_context->wallet();
    const auto network = m_account->network();
    auto session = m_context->getOrCreateSession(network);

    // TODO: autologout unsets context on the wallet
    // TODO: and this controller should detect that
    // TODO: for now, check wallet's context before continuing
    if (!wallet->context()) return;

    const quint64 count = ++m_count;
    if (m_create_task) return;

    if (!network->isLiquid()) {
        Q_ASSERT(!m_balance);
    }

    if (m_fee_rate == 0) return;

    setValid(false);

    if (m_get_unspent_outputs) return;
    if (m_all_utxos.isEmpty()) {
        m_get_unspent_outputs = new GetUnspentOutputsTask(0, false, m_account);
        connect(m_get_unspent_outputs, &Task::finished, this, [=] {
            m_all_utxos = m_get_unspent_outputs->unspentOutputs();
            m_get_unspent_outputs = nullptr;
            create();
        });
        m_dispatcher->add(m_get_unspent_outputs);
        return;
    }

    // Skip transaction creation if m_address and m_amount are empty
    // or if asset is need but not defined
    // Also clears m_transaction so that no error is shown.
    if ((m_amount.isEmpty() && m_address.isEmpty()) ||
        (network->isLiquid() && !m_balance)) {
        m_transaction = {};
        emit transactionChanged();
        return;
    }

    QJsonObject address{{ "address", m_address }};
    if (network->isLiquid()) {
        Q_ASSERT(m_balance);
        auto asset = m_balance->asset();
        address.insert("asset_id", asset->id());
        address.insert("satoshi", asset->parseAmount(m_effective_amount));
    } else {
        const qint64 amount = wallet->amountToSats(m_effective_amount);
        address.insert("satoshi", amount);
    }

    m_transaction["subaccount"] = static_cast<qint64>(m_account->pointer());
    m_transaction["fee_rate"] = network->isLiquid() && network->isElectrum() ? qMax(m_fee_rate, 100) : m_fee_rate;
    m_transaction["send_all"] = m_send_all;
    m_transaction["addressees"] = QJsonArray{address};
    m_transaction["utxo_strategy"] = m_manual_coin_selection ? "manual" : "default";
    m_transaction["utxos"] = m_manual_coin_selection ? m_utxos : m_all_utxos;

    if (m_manual_coin_selection) {
        m_transaction["used_utxos"] = m_utxos.value("btc").toArray();
    }

    m_create_task = new CreateTransactionTask(m_transaction, session);
    connect(m_create_task, &CreateTransactionTask::transaction, this, [=](const QJsonObject& transaction) {
        if (m_count == count) {
            m_transaction = transaction;

            if (m_send_all) {
                const auto id = m_balance ? m_balance->asset()->id() : "btc";
                qint64 satoshi = 0;
                Q_ASSERT(m_transaction.value("amount_read_only").toBool());
                satoshi = m_transaction.value("satoshi").toObject().value(id).toDouble();
                m_amount = m_balance ? m_balance->asset()->formatAmount(satoshi, false) : wallet->formatAmount(satoshi, false);
                if (!m_balance || m_balance->asset()->isLBTC()) m_fiat_amount = wallet->formatAmount(satoshi, false, "fiat");
                emit changed();
            }

            emit transactionChanged();
            setValid(true);
            m_count = 0;
            m_create_task = nullptr;
        } else {
            m_create_task = nullptr;
            create();
        }
    });

    m_dispatcher->add(m_create_task);
}

void SendController::signAndSend()
{
    m_transaction["memo"] = m_memo;
    const auto network = m_account->network();
    auto session = m_context->getOrCreateSession(network);
    auto sign = new SignTransactionTask(m_transaction, session);
    auto send = new SendTransactionTask(session);

    sign->then(send);

    connect(sign, &Task::finished, this, [=] {
        auto details = sign->result().value("result").toObject();
        details["memo"] = m_memo;
        send->setDetails(details);
    });
    connect(send, &Task::finished, this, [=] {
        auto transaction = m_account->getOrCreateTransaction(send->result().value("result").toObject());

        setSignedTransaction(transaction);
        // TODO context()->updateConfig();
        emit finished();
    });
    connect(send, &Task::failed, this, [=](const QString& error) {
        emit failed(error);
    });
    auto group = new TaskGroup(this);
    group->add(sign);
    group->add(send);
    m_dispatcher->add(group);
}

void SendController::setUtxos(const QJsonObject& utxos)
{
    if (m_utxos == utxos) return;
    m_utxos = utxos;
    emit utxosChanged(m_utxos);
    create();
}

void SendController::setManualCoinSelection(bool manual_coin_selection)
{
    if (m_manual_coin_selection == manual_coin_selection) return;
    m_manual_coin_selection = manual_coin_selection;
    emit changed();
    create();
}

void SendController::setSignedTransaction(Transaction* signed_transaction)
{
    if (m_signed_transaction == signed_transaction) return;
    m_signed_transaction = signed_transaction;
    emit signedTransactionChanged();
}
