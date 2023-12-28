#include "account.h"
#include "address.h"

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
