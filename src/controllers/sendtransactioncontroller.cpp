#include "sendtransactioncontroller.h"
#include "../account.h"
#include "../asset.h"
#include "../json.h"
#include "../network.h"
#include "../wallet.h"

SendTransactionController::SendTransactionController(QObject* parent)
    : AccountController(parent)
{
}

bool SendTransactionController::isValid() const
{
    return m_valid;
}

Asset* SendTransactionController::asset() const
{
    return m_asset;
}

void SendTransactionController::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged(m_asset);
    create();
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

void SendTransactionController::setAddress(const QString& address)
{
    if (m_address == address) return;
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
    if (!wallet()->network()->isLiquid()) {
        Q_ASSERT(!m_asset);
    }

    setValid(false);

    // Skip transaction creation if m_address and m_amount are empty
    // or if asset is need but not defined
    // Also clears m_transaction so that no error is shown.
    if ((m_amount.isEmpty() && m_address.isEmpty()) ||
        (wallet()->network()->isLiquid() && !m_asset)) {
        m_transaction = {};
        emit transactionChanged();
        return;
    }


    if (!m_fee_rate) {
        m_fee_rate = static_cast<qint64>(wallet()->settings().value("required_num_blocks").toInt());
    }

    QJsonObject address{{ "address", m_address }};

    if (wallet()->network()->isLiquid()) {
        address.insert("asset_tag", m_asset->id());
        address.insert("satoshi", m_asset->parseAmount(m_amount));
    } else {
        const qint64 amount = wallet()->amountToSats(m_amount);
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
        dispatch([result] (GA_session* session, GA_auth_handler** call) {
            GA_json* details = Json::fromObject(result.value("result").toObject());
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
