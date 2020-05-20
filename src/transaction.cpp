#include "account.h"
#include "asset.h"
#include "json.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"
#include <gdk.h>

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
    return { this, m_amounts };
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

    // Amounts are one time set
    if (m_amounts.empty()) {
        Wallet* wallet = m_account->wallet();
        const auto satoshi = m_data.value("satoshi").toObject();
        const int count = satoshi.keys().length();

        if (wallet->network()->isLiquid()) {
            const QString type = data.value("type").toString();

            if (type == "redeposit") {
                Q_ASSERT(satoshi.contains("btc"));
                qint64 amount = satoshi.value("btc").toDouble();
                m_amounts.append(new TransactionAmount(this, amount));
            } else if (type == "incoming") {
                for (auto i = satoshi.constBegin(); i != satoshi.constEnd(); ++i) {
                    Asset* asset = wallet->getOrCreateAsset(i.key());
                    qint64 amount = i.value().toDouble();
                    m_amounts.append(new TransactionAmount(this, asset, amount));
                }
            } else if (type == "outgoing") {
                if (count == 1) {
                    Q_ASSERT(satoshi.contains("btc"));
                    auto asset = wallet->getOrCreateAsset("btc");
                    qint64 amount = satoshi.value("btc").toDouble();
                    m_amounts.append(new TransactionAmount(this, asset, amount));
                } else {
                    for (auto i = satoshi.constBegin(); i != satoshi.constEnd(); ++i) {
                        qint64 amount = i.value().toDouble();
                        if (i.key() == "btc") {
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
                Q_UNREACHABLE();
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

void Transaction::updateMemo(const QString &memo)
{
    if (memo == m_data.value("memo").toString()) return;

    Q_ASSERT(memo.length() <= 1024);

    QMetaObject::invokeMethod(m_account->m_wallet->m_context, [this, memo] {
        auto txhash = m_data.value("txhash").toString().toLocal8Bit();
        int err = GA_set_transaction_memo(m_account->m_wallet->m_session, txhash.constData(), memo.toLocal8Bit().constData(), GA_MEMO_USER);
        Q_ASSERT(err == GA_OK);

        m_data["memo"] = memo;
        emit dataChanged(m_data);
    });
}
