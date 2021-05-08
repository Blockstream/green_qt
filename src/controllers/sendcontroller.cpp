#include "account.h"
#include "asset.h"
#include "balance.h"
#include "handlers/createtransactionhandler.h"
#include "handlers/sendtransactionhandler.h"
#include "handlers/signtransactionhandler.h"
#include "json.h"
#include "network.h"
#include "sendcontroller.h"
#include "wallet.h"

SendController::SendController(QObject* parent)
    : AccountController(parent)
{
    connect(this, &SendController::accountChanged, this, &SendController::create);
    connect(this, &SendController::walletChanged, this, &SendController::create);
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
    if (!wallet()) return false;
    if (!wallet()->network()->isLiquid()) return true;
    if (m_balance && m_balance->asset()->data().value("name").toString() == "btc") return true;
    return false;
}

QJsonObject SendController::transaction() const
{
    return m_transaction;
}

void SendController::update()
{
    if (!wallet()) return;
    const bool is_liquid = wallet()->network()->isLiquid();
    if (hasFiatRate()) {
        auto unit = wallet()->settings().value("unit").toString();
        unit = unit == "\u00B5BTC" ? "ubtc" : unit.toLower();
        QJsonObject convert;

        if (m_send_all) {
            if (is_liquid) {
                if (m_balance) {
                    convert.insert("sats", QString::number(m_balance->amount()));
                }
            } else {
                auto satoshi = account()->json().value("satoshi").toObject();
                Q_ASSERT(satoshi.contains("btc"));
                convert.insert("sats", QString::number(satoshi.value("btc").toDouble()));
            }
        } else if (!m_amount.isEmpty()) {
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

        const auto res = wallet()->convert(convert);
        m_effective_amount = res.value(unit).toString();
        m_effective_fiat_amount = res.value("fiat").isNull() ? "n/a" : res.value("fiat").toString();
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
    if (!wallet() || !account()) return;

    const quint64 count = ++m_count;
    if (m_create_handler) return;

    if (!wallet()->network()->isLiquid()) {
        Q_ASSERT(!m_balance);
    }

    setValid(false);

    // Skip transaction creation if m_address and m_amount are empty
    // or if asset is need but not defined
    // Also clears m_transaction so that no error is shown.
    if ((m_amount.isEmpty() && m_address.isEmpty()) ||
        (wallet()->network()->isLiquid() && !m_balance)) {
        m_transaction = {};
        emit transactionChanged();
        return;
    }

    if (!m_fee_rate) {
        m_fee_rate = static_cast<qint64>(wallet()->settings().value("required_num_blocks").toInt());
    }

    QJsonObject address{{ "address", m_address }};
    auto asset = m_balance ? m_balance->asset() : nullptr;
    if (wallet()->network()->isLiquid() && asset->data().value("name").toString() != "btc") {
        address.insert("asset_tag", asset->id());
        address.insert("satoshi", asset->parseAmount(m_effective_amount));
    } else {
        const qint64 amount = wallet()->amountToSats(m_effective_amount);
        address.insert("satoshi", amount);
    }
    QJsonObject data{
        { "subaccount", static_cast<qint64>(account()->pointer()) },
        { "fee_rate", m_fee_rate },
        { "send_all", m_send_all },
        { "addressees", QJsonArray{address}}
    };

    m_create_handler = new CreateTransactionHandler(wallet(), data);
    connect(m_create_handler, &Handler::done, this, [this, count] {
        if (m_count == count) {
            m_transaction = m_create_handler->result().value("result").toObject();
            emit transactionChanged();
            setValid(true);
            m_count = 0;
            m_create_handler = nullptr;
        } else {
            m_create_handler = nullptr;
            create();
        }
    });
    exec(m_create_handler);
}

void SendController::signAndSend()
{
    auto sign = new SignTransactionHandler(wallet(), m_transaction);
    connect(sign, &Handler::done, this, [this, sign] {
        // sign->deleteLater();
        auto details = sign->result().value("result").toObject();
        details["memo"] = m_memo;
        auto send = new SendTransactionHandler(wallet(), details);
        connect(send, &Handler::done, this, [this, send] {
            auto tx = send->result().value("result").toObject();
            setSignedTransaction(m_account->getOrCreateTransaction(tx));
            send->deleteLater();
            wallet()->updateConfig();
            emit finished();
        });
        exec(send);
    });
    exec(sign);
}

Transaction* SendController::signedTransaction() const
{
    return m_signed_transaction;
}

void SendController::setSignedTransaction(Transaction* signed_transaction)
{
    if (m_signed_transaction!=signed_transaction) {
        m_signed_transaction = signed_transaction;
        emit signedTransactionChanged(m_signed_transaction);
    }
}
