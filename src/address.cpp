#include "account.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "address.h"
#include "util.h"
#include "wallet.h"
#include <gdk.h>

Address::Address(Account* account)
    : QObject(account)
    , m_account(account)
{
}

Address::~Address()
{
}

void Address::updateFromData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged(m_data);
}

