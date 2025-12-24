#include "account.h"
#include "address.h"
#include "context.h"
#include "network.h"

#include <gdk.h>

Address::Address(Context* context, const QString& address)
    : QObject(context)
    , m_context(context)
    , m_address(address)
{
}

void Address::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
}

void Address::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    m_pointer = m_data.value("pointer").toInt();
    m_type = m_data.value("address_type").toString();
    emit dataChanged();
}

void Address::setVerified(bool verified)
{
    if (m_verified == verified) return;
    m_verified = verified;
    emit verifiedChanged();
}

QUrl Address::url() const
{
    const auto address_explorer_url = m_account->network()->data().value("address_explorer_url").toString();
    return { address_explorer_url + m_address };
}
