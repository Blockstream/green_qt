#include "account.h"
#include "address.h"
#include "network.h"

#include <gdk.h>

Address::Address(Account* account)
    : QObject(account)
    , m_account(account)
{
}

void Address::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    m_pointer = m_data.value("pointer").toInt();
    m_type = m_data.value("address_type").toString();
    m_address = m_data.value("address").toString();
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
