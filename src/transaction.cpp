#include "account.h"
#include "asset.h"
#include "context.h"
#include "lightning/lightningclient.h"
#include "lightning/lightningutil.h"
#include "network.h"
#include "output.h"
#include "session.h"
#include "transaction.h"
#include "util.h"
#include "wallet.h"

#include <gdk.h>

namespace  {

AccountTransaction::Type ParseType(const QString& type)
{
    if (type == QStringLiteral("incoming")) return AccountTransaction::Type::Incoming;
    if (type == QStringLiteral("outgoing")) return AccountTransaction::Type::Outgoing;
    if (type == QStringLiteral("redeposit")) return AccountTransaction::Type::Redeposit;
    if (type == QStringLiteral("mixed")) return AccountTransaction::Type::Mixed;
    if (type == QStringLiteral("not unblindable")) return AccountTransaction::Type::NotUnblindable;
    return AccountTransaction::Type::Unknown;
}

QString LightningPaymentTypeString(const LightningPaymentType type)
{
    switch (type) {
    case LightningPaymentType::Received: return QStringLiteral("incoming");
    case LightningPaymentType::Sent: return QStringLiteral("outgoing");
    case LightningPaymentType::Unknown: return QStringLiteral("unknown");
    }
    return QStringLiteral("unknown");
}

} // namespace

AccountTransaction::AccountTransaction(ChainTransaction* chain_transaction, Account* account)
    : ContextTransaction(chain_transaction->id(), account->context())
    , m_chain_transaction(chain_transaction)
    , m_account(account)
{
}

AccountTransaction::~AccountTransaction()
{
}

QDateTime AccountTransaction::timestamp() const
{
    const auto created_at_ts = m_data.value("created_at_ts");
    const auto timestamp = created_at_ts.isNull() ? QDateTime::currentDateTime() : QDateTime::fromMSecsSinceEpoch(created_at_ts.toInteger() / 1000);
    return timestamp;
}

bool AccountTransaction::isUnconfirmed() const
{
    return m_data.value("block_height").toInt(0) == 0;
}

Account* AccountTransaction::account() const
{
    return m_account;
}

QJsonObject AccountTransaction::data() const
{
    return m_data;
}

QUrl AccountTransaction::url() const
{
    const auto tx_explorer_url = m_account->network()->data().value("tx_explorer_url").toString();
    const auto txhash = m_data.value("txhash").toString();
    return { tx_explorer_url + txhash };
}

bool AccountTransaction::hasAsset(Asset* asset) const
{
    return m_data.value("satoshi").toObject().contains(asset->id());
}

void AccountTransaction::setPayment(Payment* payment)
{
    if (m_payment == payment) return;
    m_payment = payment;
    emit paymentChanged();
}

QJsonObject AccountTransaction::destination() const
{
    const auto outputs = m_data.value("outputs").toArray();
    for (int i = 0; i < outputs.size(); i++) {
        const auto output = outputs.at(i).toObject();
        if (!output.contains("satoshi")) continue;
        if (type() == Type::Redeposit) return output;
        if (m_account->network()->isLiquid()) {
            if (output.value("script").toString().isEmpty()) continue;
            if (output.value("is_internal").toBool()) continue;
        } else {
            if (output.value("is_relevant").toBool()) continue;
        }
        return output;
    }
    return {};
}

void AccountTransaction::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();

    setType(ParseType(m_data.value("type").toString()));
    setMemo(m_data.value("memo").toString());


    const auto inputs = m_data.value("inputs").toArray();
    for (const auto input : inputs) {
        auto output = m_account->getOrCreateOutput(input.toObject());
        if (output) {
            output->setSpendingTransaction(this);
        }
    }
}

void AccountTransaction::openInExplorer() const
{
    m_account->network()->openTransactionInExplorer(m_data.value("txhash").toString());
}

QString AccountTransaction::link()
{
    return m_account->network()->explorerUrl() + m_data.value("txhash").toString();
}

QString AccountTransaction::unblindedLink()
{
    const auto network = m_account->network();
    Q_ASSERT(network->isLiquid());

    auto tx_explorer_url = network->explorerUrl();

    const auto inputs = m_data.value("inputs").toArray();
    const auto outputs = m_data.value("outputs").toArray();

    QStringList args;

    auto append_blinding_data = [&](const QJsonValue& value) {
        QJsonObject o = value.toObject();

        if (!o.contains("satoshi") || o["satoshi"].toDouble() == 0) return;
        if (!o.contains("assetblinder") || o["assetblinder"].toString() == "") return;
        if (!o.contains("amountblinder") || o["amountblinder"].toString() == "") return;

        args.append(QString::number(ParseSatoshi(o["satoshi"])));
        args.append(o["asset_id"].toString());
        args.append(o["amountblinder"].toString());
        args.append(o["assetblinder"].toString());
    };

    for (const auto &v : inputs) append_blinding_data(v);
    for (const auto &v : outputs) append_blinding_data(v);

    return QString("%1%2#blinded=%3").arg(tx_explorer_url, m_data.value("txhash").toString(), args.join(','));
}

void AccountTransaction::updateMemo(const QString& memo)
{
    if (memo.length() > 1024) return;
    if (m_memo == memo) return;
    auto txhash = m_data.value("txhash").toString().toLocal8Bit();
    if (!m_account->session()) return;
    auto session = m_account->session()->m_session;
    if (!session) return;
    int rc = GA_set_transaction_memo(session, txhash.constData(), memo.toUtf8().constData(), 0);
    if (rc != GA_OK) return;
    setMemo(memo);
}

void AccountTransaction::setType(AccountTransaction::Type type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged();
}

void AccountTransaction::setMemo(const QString& memo)
{
    if (m_memo == memo) return;
    m_memo = memo;
    emit memoChanged();
}

ChainTransaction::ChainTransaction(const QString &id, Context* context)
    : ContextTransaction(id, context)
{
}

void ChainTransaction::setSwap(Swap* swap)
{
    if (m_swap == swap) return;
    m_swap = swap;
    emit swapChanged();
}

LightningTransaction::LightningTransaction(const QString& id, Context* context)
    : ContextTransaction(id, context)
{
}

QDateTime LightningTransaction::timestamp() const
{
    const auto created_at_ts = m_data.value("created_at_ts");
    const auto timestamp = created_at_ts.isNull() ? QDateTime::currentDateTime() : QDateTime::fromMSecsSinceEpoch(created_at_ts.toInteger() / 1000);
    return timestamp;
}

void LightningTransaction::updateFromPayment(const LightningPayment& payment)
{
    const auto type = LightningPaymentTypeString(payment.payment_type);
    const auto fee = LightningMsatToSatoshi(payment.fee_msat);
    auto amount = static_cast<qint64>(LightningMsatToSatoshi(payment.amount_msat));
    if (payment.payment_type == LightningPaymentType::Sent) {
        // GL-SDK doesn't include the fee in the amount for sent payments,
        // but we want to show the total outgoing amount in the UI.
        amount += static_cast<qint64>(fee);
        amount = -amount;
    }

    QJsonObject data{
        { QStringLiteral("txhash"), payment.id },
        { QStringLiteral("type"), type },
        { QStringLiteral("satoshi"), QJsonObject{{ QStringLiteral("lnbtc"), amount }} },
        { QStringLiteral("fee"), static_cast<qint64>(fee) },
        { QStringLiteral("created_at_ts"), static_cast<qint64>(payment.payment_time) * 1000000 },
    };

    if (payment.description) data.insert(QStringLiteral("description"), *payment.description);
    if (payment.bolt11) data.insert(QStringLiteral("bolt11"), *payment.bolt11);
    if (payment.preimage) data.insert(QStringLiteral("preimage"), *payment.preimage);
    if (payment.destination) data.insert(QStringLiteral("destination"), *payment.destination);

    if (m_data == data) return;
    m_data = data;
    emit dataChanged();
}
