#include "account.h"
#include "json.h"
#include "transaction.h"
#include "wallet.h"
#include <gdk.h>

#include <QClipboard>
#include <QGuiApplication>

Transaction::Transaction(Account* account)
    : QObject(account)
    , m_account(account)
{

}

Transaction::~Transaction()
{

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
