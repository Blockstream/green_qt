#include "account.h"
#include "asset.h"
#include "context.h"
#include "network.h"
#include "output.h"
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
    if (type == QStringLiteral("not unblindable")) return Transaction::Type::NotUnblindable;
    return Transaction::Type::Unknown;
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

Transaction::Transaction(const QString& hash, Account* account)
    : QObject(account)
    , m_account(account)
    , m_hash(hash)
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

QUrl Transaction::url() const
{
    const auto tx_explorer_url = m_account->network()->data().value("tx_explorer_url").toString();
    const auto txhash = m_data.value("txhash").toString();
    return { tx_explorer_url + txhash };
}

bool Transaction::hasAsset(Asset *asset) const
{
    for (auto amount : m_amounts) {
        if (amount->asset() == asset) return true;
    }
    return false;
}

QJsonObject Transaction::destination() const
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

void Transaction::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();

    setType(ParseType(m_data.value("type").toString()));
    setMemo(m_data.value("memo").toString());

    // Amounts are one time set
    const auto satoshi = m_data.value("satoshi").toObject();

    // FIXME: because redeposits have incorrect satoshi.btc values we compute
    // amounts again. note that above we early return if m_data doesn't change.
    auto amounts = m_amounts;
    m_amounts.clear();
    const auto network = m_account->network();
    if (network->isLiquid()) {
        const auto policy_asset = network->policyAsset();
        qint64 fee = m_data.value("fee").toInteger();
        for (auto i = satoshi.constBegin(); i != satoshi.constEnd(); ++i) {
            qint64 amount = i.value().toInteger();
            Asset* asset = context()->getOrCreateAsset(i.key());
            if ((asset->id() == policy_asset) && (amount < 0) && (fee > 0)) {
                amount += fee;
                fee = 0;
            }
            if (amount != 0) {
                m_amounts.append(new TransactionAmount(this, asset, amount));
            }
        }
    } else {
        qint64 amount = satoshi.value("btc").toInteger();
        m_amounts.append(new TransactionAmount(this, context()->getOrCreateAsset("btc"), amount));
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

void Transaction::setType(Transaction::Type type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged();
}

void Transaction::setMemo(const QString& memo)
{
    if (m_memo == memo) return;
    m_memo = memo;
    emit memoChanged();
}
