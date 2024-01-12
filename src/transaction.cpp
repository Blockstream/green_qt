#include "account.h"
#include "asset.h"
#include "context.h"
#include "network.h"
#include "session.h"
#include "transaction.h"
#include "util.h"
#include "wallet.h"

#include <gdk.h>

namespace  {

Transaction::Type ParseType(const QString& type)
{
    if (type == QStringLiteral("incoming")) return Transaction::Type::Incoming;
    if (type == QStringLiteral("outgoing")) return Transaction::Type::Outgoing;
    if (type == QStringLiteral("redeposit")) return Transaction::Type::Redeposit;
    if (type == QStringLiteral("mixed")) return Transaction::Type::Mixed;
    return Transaction::Type::Unknown;
}

Transaction::SPVStatus ParseSVPStatus(const QString& spv_status)
{
    if (spv_status == QStringLiteral("unconfirmed")) return Transaction::SPVStatus::Unconfirmed;
    if (spv_status == QStringLiteral("in_progress")) return Transaction::SPVStatus::InProgress;
    if (spv_status == QStringLiteral("verified")) return Transaction::SPVStatus::Verified;
    if (spv_status == QStringLiteral("not_verified")) return Transaction::SPVStatus::NotVerified;
    if (spv_status == QStringLiteral("not_longest")) return Transaction::SPVStatus::NotLongest;
    if (spv_status == QStringLiteral("disabled")) return Transaction::SPVStatus::Disabled;
    return Transaction::SPVStatus::Disabled;
}

} // namespace

TransactionAmount::TransactionAmount(Transaction *transaction, qint64 amount)
    : TransactionAmount(transaction, nullptr, amount)
{
}

TransactionAmount::TransactionAmount(Transaction* transaction, Asset* asset, qint64 amount)
    : QObject(transaction)
    , m_transaction(transaction)
    , m_asset(asset)
    , m_amount(amount)
{
    Q_ASSERT(m_transaction);
}

TransactionAmount::~TransactionAmount()
{
}

QString TransactionAmount::formatAmount(bool include_ticker) const
{
    if (m_asset) {
        return m_asset->formatAmount(m_amount, include_ticker);
    } else {
        const auto wallet = m_transaction->account()->context()->wallet();
        return wallet->formatAmount(m_amount, include_ticker);
    }
}

Transaction::Transaction(Account* account)
    : QObject(account)
    , m_account(account)
{
}

Transaction::~Transaction()
{
}

bool Transaction::isUnconfirmed() const
{
    return m_data.value("block_height").toInt(0) == 0;
}

Context* Transaction::context() const
{
    return m_account->context();
}

Account *Transaction::account() const
{
    return m_account;
}

QQmlListProperty<TransactionAmount> Transaction::amounts()
{
    return { this, &m_amounts };
}

QJsonObject Transaction::data() const
{
    return m_data;
}

void Transaction::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged(m_data);

    setType(ParseType(m_data.value("type").toString()));
    setMemo(m_data.value("memo").toString());
    setSpvStatus(ParseSVPStatus(m_data.value("spv_verified").toString()));

    // Amounts are one time set
    const auto satoshi = m_data.value("satoshi").toObject();

    // FIXME: because redeposits have incorrect satoshi.btc values we compute
    // amounts again. note that above we early return if m_data doesn't change.
    auto amounts = m_amounts;
    m_amounts.clear();
    const auto network = m_account->network();
    if (network->isLiquid()) {
        const auto policy_asset = network->policyAsset();
        const qint64 fee = m_data.value("fee").toInteger();
        for (auto i = satoshi.constBegin(); i != satoshi.constEnd(); ++i) {
            qint64 amount = i.value().toInteger();
            Asset* asset = context()->getOrCreateAsset(i.key());
            if (asset->id() == policy_asset && amount < 0) amount += fee;
            if (amount != 0) m_amounts.append(new TransactionAmount(this, asset, amount));
        }
    } else {
        qint64 amount = satoshi.value("btc").toInteger();
        m_amounts.append(new TransactionAmount(this, amount));
    }

    emit amountsChanged();
    qDeleteAll(amounts);
}

void Transaction::openInExplorer() const
{
    m_account->network()->openTransactionInExplorer(m_data.value("txhash").toString());
}

QString Transaction::link()
{
    return m_account->network()->explorerUrl() + m_data.value("txhash").toString();
}

QString Transaction::unblindedLink()
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

void Transaction::updateMemo(const QString& memo)
{
    Q_ASSERT(memo.length() <= 1024);
    if (m_memo == memo) return;
    auto txhash = m_data.value("txhash").toString().toLocal8Bit();
    int err = GA_set_transaction_memo(m_account->session()->m_session, txhash.constData(), memo.toUtf8().constData(), 0);
    Q_ASSERT(err == GA_OK);
    setMemo(memo);
}

void Transaction::setType(Transaction::Type type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
}

void Transaction::setMemo(const QString& memo)
{
    if (m_memo == memo) return;
    m_memo = memo;
    emit memoChanged(m_memo);
}

void Transaction::setSpvStatus(Transaction::SPVStatus spv_status)
{
    if (m_spv_status == spv_status) return;
    m_spv_status = spv_status;
    emit spvStatusChanged(m_spv_status);
}
