#include "account.h"
#include "address.h"
#include "context.h"
#include "payment.h"
#include "transaction.h"

Payment::Payment(Context* context)
    : QObject(context)
    , m_context(context)
{
}

void Payment::update(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();

    refresh();
}

void Payment::refresh()
{
    setUpdatedAt(QDateTime::fromString(m_data.value("updatedAt").toString(), Qt::ISODateWithMs));
    setStatus(m_data.value("status").toString());

    const auto crypto_details = m_data.value("cryptoDetails").toObject();

    if (!m_address) {
        const auto destination_wallet_address = crypto_details.value("destinationWalletAddress").toString();

        if (!destination_wallet_address.isEmpty()) {
            m_address = m_context->getAddress(destination_wallet_address);
            emit addressChanged();
        }
    }

    const auto blockchain_transaction_id = crypto_details.value("blockchainTransactionId").toString();
    Transaction* transaction{nullptr};

    if (!blockchain_transaction_id.isEmpty()) {
        const auto transactions = m_context->getTransaction(blockchain_transaction_id);
        if (!transactions.isEmpty()) transaction = transactions.first();
    }

    if (m_transaction == transaction) {
        return;
    }

    if (m_transaction) {
        m_transaction->setPayment(nullptr);
        m_transaction = nullptr;
    }

    if (transaction) {
        m_transaction = transaction;
        m_transaction->setPayment(this);
    }

    emit transactionChanged();
}

void Payment::setUpdatedAt(const QDateTime &updated_at)
{
    if (m_updated_at == updated_at) return;
    m_updated_at = updated_at;
    emit updatedAtChanged();
}

void Payment::setStatus(const QString& status)
{
    if (m_status == status) return;
    m_status = status;
    emit statusChanged();
}
