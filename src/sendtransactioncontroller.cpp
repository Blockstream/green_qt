#include "sendtransactioncontroller.h"
#include "account.h"
#include "asset.h"
#include "balance.h"
#include "json.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"

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
                auto x = account()->json().value("satoshi").toObject();
                qDebug() << x;
                convert.insert("sats", QString::number(x.value("btc").toDouble()));
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

    const quint64 count = ++m_count;
    QMetaObject::invokeMethod(context(), [this, count, data] {
        // Check if meanwhile create() was called again, if so avoid
        // calling GA_create_transaction
        bool run;
        QMetaObject::invokeMethod(this, [this, count] () -> bool {
            return m_count == count;
        }, Qt::BlockingQueuedConnection, &run);
        if (!run) return;

        auto result = GA::process_auth([this, data] (GA_auth_handler** call) {
            auto details = Json::fromObject(data);
            int err = GA_create_transaction(session(), details, call);
            Q_ASSERT(err == GA_OK);
            err = GA_destroy_json(details);
            Q_ASSERT(err == GA_OK);
        });
        Q_ASSERT(result.value("status").toString() == "done");
        m_transaction = result.value("result").toObject();

        // Check if the m_transaction isn't outdated and emit respective
        // signal, otherwise there's already another create enqueued.
        QMetaObject::invokeMethod(this, [this, count] {
            if (m_count == count) {
                m_count = 0;
                emit transactionChanged();
                setValid(true);
            }
        }, Qt::BlockingQueuedConnection);
    });
}

void SendTransactionController::send()
{
    dispatch([this] (GA_session* session, GA_auth_handler** call) {
        GA_json* details = Json::fromObject(m_transaction);
        int err = GA_sign_transaction(session, details, call);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    });
}

bool SendTransactionController::update(const QJsonObject& result)
{
    auto status = result.value("status").toString();
    auto action = result.value("action").toString();

    if (status == "done" && action == "sign_tx") {
        dispatch([this, result] (GA_session* session, GA_auth_handler** call) {
            auto tx = result.value("result").toObject();
            tx["memo"] = m_memo;
            GA_json* details = Json::fromObject(tx);
            int err = GA_send_transaction(session, details, call);
            Q_ASSERT(err == GA_OK);
            err = GA_destroy_json(details);
            Q_ASSERT(err == GA_OK);
        });
        return false;
    }

    if (status == "done" && action == "send_raw_tx") {
        wallet()->updateConfig();
        return true;
    }

    return AccountController::update(result);
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

    dispatch([this] (GA_session* session, GA_auth_handler** call) {
        GA_json* details = Json::fromObject(m_tx);
        int err = GA_sign_transaction(session, details, call);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    });
}

bool BumpFeeController::update(const QJsonObject &result)
{
    bool res = AccountController::update(result);
    if (result.value("status").toString() != "done") {
        return res;
    }
    auto action = result.value("action").toString();
//    if (action == "create_transaction") {
//        tx = result.value("result").toObject();
//        return false;
//    }
    if (action == "sign_tx") {
        dispatch([result] (GA_session* session, GA_auth_handler** call) {
            GA_json* details = Json::fromObject(result.value("result").toObject());
            int err = GA_send_transaction(session, details, call);
            Q_ASSERT(err == GA_OK);
            err = GA_destroy_json(details);
            Q_ASSERT(err == GA_OK);
        });
        return true;
    } else if (action == "send_raw_tx") {
        wallet()->updateConfig();
        return true;
    }
    Q_UNREACHABLE();
}

void BumpFeeController::create()
{
    if (!account()) return;
    if (!wallet()) return;
    if (!transaction()) return;
    int req = ++m_req;
    auto s = session();
    auto t = transaction();
    auto a = account();

    GA_json* details = Json::fromObject({
        { "subaccount", static_cast<qint64>(a->m_pointer) },
        { "fee_rate", m_fee_rate },
        { "previous_transaction", t->data() }
    });

    QMetaObject::invokeMethod(context(), [this, req, s, details] {
        if (m_req != req) return;
        auto r = GA::process_auth([s, details](GA_auth_handler** call) {
            int err = GA_create_transaction(s, details, call);
            Q_ASSERT(err == GA_OK);
            err = GA_destroy_json(details);
            Q_ASSERT(err == GA_OK);
        });

        // Check if the m_transaction isn't outdated and emit respective
        // signal, otherwise there's already another create enqueued.
        QMetaObject::invokeMethod(this, [this, req, r] {
            if (m_req != req) return;
            m_tx = r.value("result").toObject();
            emit txChanged(m_tx);
            qDebug() << "CREATE" << m_fee_rate;
        }, Qt::BlockingQueuedConnection);
    });
}
