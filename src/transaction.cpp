#include "account.h"
#include "asset.h"
#include "json.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"
#include <gdk.h>

#include <QClipboard>
#include <QGuiApplication>

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

QString TransactionAmount::formatAmount() const
{
    QString prefix = m_transaction->data().value("type").toString() != "incoming" ? "-" : "";
    if (m_asset) {
        return prefix + m_asset->formatAmount(m_amount, true);
    } else {
        return prefix + m_transaction->account()->wallet()->formatAmount(m_amount, true);
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

QJsonObject Transaction::data() const
{
    return m_data;
}

void Transaction::updateFromData(const QJsonObject &data)
{
    m_data = data;
    emit dataChanged(data);
}

void Transaction::copyTxhashToClipboard() const
{
    QGuiApplication::clipboard()->setText(m_data.value("txhash").toString());
}

void Transaction::openInExplorer() const
{
    m_account->wallet()->network()->openTransactionInExplorer(m_data.value("txhash").toString());
}

void Transaction::updateMemo(const QString &memo)
{
    if (memo == m_data.value("memo").toString()) return;

    QMetaObject::invokeMethod(m_account->m_wallet->m_context, [this, memo] {
        auto txhash = m_data.value("txhash").toString().toLocal8Bit();
        int err = GA_set_transaction_memo(m_account->m_wallet->m_session, txhash.constData(), memo.toLocal8Bit().constData(), GA_MEMO_USER);
        Q_ASSERT(err == GA_OK);

        m_data["memo"] = memo;
        emit dataChanged(m_data);
    });
}
