#include "sendtransactioncontroller.h"
#include "account.h"
#include "asset.h"
#include "balance.h"
#include "handler.h"
#include "json.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"

#include <gdk.h>

#include <QDebug>

class CreateTransactionHandler : public Handler
{
    const QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        qDebug() << "create transaction" << m_details;
        auto details = Json::fromObject(m_details);
        int err = GA_create_transaction(session, details, auth_handler);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    }
public:
    CreateTransactionHandler(QJsonObject& details, Wallet* wallet)
        : Handler(wallet)
        , m_details(details)
    {
    }
};

SendTransactionController::SendTransactionController(QObject* parent)
    : AccountController(parent)
{
    connect(this, &SendTransactionController::accountChanged, this, &SendTransactionController::create);
    connect(this, &SendTransactionController::walletChanged, this, &SendTransactionController::create);
}

bool SendTransactionController::isValid() const
{
    return m_valid;
}

Balance* SendTransactionController::balance() const
{
    return m_balance;
}

void SendTransactionController::setBalance(Balance* balance)
{
    if (m_balance == balance) return;
    m_balance = balance;
    m_amount.clear();
    m_fiat_amount.clear();
    update();
}

void SendTransactionController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit changed();
}

QString SendTransactionController::address() const
{
    return m_address;
}

void SendTransactionController::setAddress(const QString& address)
{
    if (m_address == address) return;
    m_address = address;
    emit changed();
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
    m_amount.clear();
    m_fiat_amount.clear();
    update();
}

void SendTransactionController::setAmount(const QString& amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    m_fiat_amount.clear();
    update();
}

void SendTransactionController::setFiatAmount(const QString& fiat_amount)
{
    Q_ASSERT(hasFiatRate());
    if (m_fiat_amount == fiat_amount) return;
    m_fiat_amount = fiat_amount;
    m_amount.clear();
    update();
}

QString SendTransactionController::memo() const
{
    return m_memo;
}

void SendTransactionController::setMemo(const QString &memo)
{
    if (m_memo == memo) return;
    Q_ASSERT(memo.length() <= 1024);
    m_memo = memo;
    emit changed();
}

qint64 SendTransactionController::feeRate() const
{
    return m_fee_rate;
}

void SendTransactionController::setFeeRate(qint64 fee_rate)
{
    if (m_fee_rate == fee_rate) return;
    m_fee_rate = fee_rate;
    emit changed();
    create();
}

bool SendTransactionController::hasFiatRate() const
{
    if (!wallet()) return false;
    if (!wallet()->network()->isLiquid()) return true;
    if (m_balance && m_balance->asset()->data().value("name").toString() == "btc") return true;
    return false;
}

QJsonObject SendTransactionController::transaction() const
{
    return m_transaction;
}

void SendTransactionController::update()
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

void SendTransactionController::create()
{
    if (!wallet()) return;

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
        { "subaccount", static_cast<qint64>(account()->m_pointer) },
        { "fee_rate", m_fee_rate },
        { "send_all", m_send_all },
        { "addressees", QJsonArray{address}}
    };

    m_create_handler = new CreateTransactionHandler(data, wallet());
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

class SignTransactionHandler : public Handler
{
    const QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        GA_json* details = Json::fromObject(m_details);
        int err = GA_sign_transaction(session, details, auth_handler);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    }
public:
    SignTransactionHandler(const QJsonObject& details, Wallet *wallet)
        : Handler(wallet)
        , m_details(details)
    {
    }
};

class SendTransactionHandler : public Handler
{
    const QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        GA_json* details = Json::fromObject(m_details);
        int err = GA_send_transaction(session, details, auth_handler);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    }
public:
    SendTransactionHandler(const QJsonObject& details, Wallet* wallet)
        : Handler(wallet)
        , m_details(details)
    {
    }
};

void SendTransactionController::signAndSend()
{
    auto sign = new SignTransactionHandler(m_transaction, wallet());
    connect(sign, &Handler::done, this, [this, sign] {
        // sign->deleteLater();
        auto details = sign->result().value("result").toObject();
        details["memo"] = m_memo;
        auto send = new SendTransactionHandler(details, wallet());
        connect(send, &Handler::done, this, [this, send] {
           send->deleteLater();
           wallet()->updateConfig();
           emit finished();
        });
        exec(send);
    });
    exec(sign);
}

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
    auto sign = new SignTransactionHandler(m_tx, wallet());
    connect(sign, &Handler::done, this, [this, sign] {
        auto details = sign->result().value("result").toObject();
        auto send = new SendTransactionHandler(details, wallet());
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
        { "subaccount", static_cast<qint64>(a->m_pointer) },
        { "fee_rate", m_fee_rate },
        { "previous_transaction", t->data() }
    };

    m_create_handler = new CreateTransactionHandler(details, wallet());
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
