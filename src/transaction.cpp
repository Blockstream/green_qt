#include "account.h"
#include "asset.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "transaction.h"
#include "util.h"
#include "wallet.h"
#include <gdk.h>

namespace  {

Transaction::SPVStatus ParseSVPStatus(const QString& spv_status)
{
    if (spv_status == QStringLiteral("unconfirmed")) return Transaction::SPVStatus::Unconfirmed;
    if (spv_status == QStringLiteral("in_progress")) return Transaction::SPVStatus::InProgress;
    if (spv_status == QStringLiteral("verified")) return Transaction::SPVStatus::Verified;
    if (spv_status == QStringLiteral("not_verified")) return Transaction::SPVStatus::NotVerified;
    if (spv_status == QStringLiteral("not_longest")) return Transaction::SPVStatus::NotLongest;
    if (spv_status == QStringLiteral("disabled")) return Transaction::SPVStatus::Disabled;
    Q_UNREACHABLE();
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
    Q_ASSERT(!m_asset || m_asset->wallet() == transaction->account()->wallet());
    Q_ASSERT(m_amount > 0);
}

TransactionAmount::~TransactionAmount()
{
}

QString TransactionAmount::formatAmount(bool include_ticker) const
{
    QString prefix = m_transaction->data().value("type").toString() != "incoming" ? "-" : "";
    if (m_asset) {
        return prefix + m_asset->formatAmount(m_amount, include_ticker);
    } else {
        return prefix + m_transaction->account()->wallet()->formatAmount(m_amount, include_ticker);
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

    setMemo(m_data.value("memo").toString());
    setSpvStatus(ParseSVPStatus(m_data.value("spv_verified").toString()));

    // Amounts are one time set
    const auto satoshi = m_data.value("satoshi").toObject();
    const int count = satoshi.keys().length();

    if (m_amounts.empty() && count > 0) {
        Wallet* wallet = m_account->wallet();
        const auto satoshi = m_data.value("satoshi").toObject();
        if (wallet->network()->isLiquid()) {
            const auto type = data.value("type").toString();
            if (type == "incoming" || type == "redeposit") {
                for (auto i = satoshi.constBegin(); i != satoshi.constEnd(); ++i) {
                    qint64 amount = i.value().toDouble();
                    if (amount > 0) {
                        Asset* asset = wallet->getOrCreateAsset(i.key());
                        m_amounts.append(new TransactionAmount(this, asset, amount));
                    }
                }
            } else if (type == "outgoing") {
                for (auto i = satoshi.constBegin(); i != satoshi.constEnd(); ++i) {
                    qint64 amount = i.value().toDouble();
                    if (i.key() == wallet->network()->policyAsset()) {
                        qint64 fee = data.value("fee").toDouble();
                        Q_ASSERT(fee <= amount);
                        amount -= fee;
                        if (amount == 0) continue; // just fee
                    }
                    Asset* asset = wallet->getOrCreateAsset(i.key());
                    m_amounts.append(new TransactionAmount(this, asset, amount));
                }
            }
        } else {
            qint64 amount = satoshi.value("btc").toDouble();
            m_amounts.append(new TransactionAmount(this, amount));
        }

        emit amountsChanged();
    }
}

void Transaction::openInExplorer() const
{
    m_account->wallet()->network()->openTransactionInExplorer(m_data.value("txhash").toString());
}

QString Transaction::unblindedLink() const
{
    Q_ASSERT(account()->wallet()->network()->isLiquid());

    auto tx_explorer_url = m_account->wallet()->network()->explorerUrl();

    const auto inputs = m_data.value("inputs").toArray();
    const auto outputs = m_data.value("outputs").toArray();

    QStringList args;

    auto append_blinding_data = [&](const QJsonValue& value) {
        QJsonObject o = value.toObject();

        if (!o.contains("satoshi") || o["satoshi"].toInt() == 0) return;
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
    int err = GA_set_transaction_memo(m_account->wallet()->m_session->m_session, txhash.constData(), memo.toLocal8Bit().constData(), 0);
    Q_ASSERT(err == GA_OK);
    setMemo(memo);
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
