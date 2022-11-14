#include "getaddresseshandler.h"

#include "account.h"
#include "json.h"
#include "wallet.h"

#include <gdk.h>

void GetAddressesHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    QJsonObject _details({{ "subaccount", static_cast<qint64>(m_subaccount) }});
    if (m_last_pointer != 0) _details["last_pointer"] = m_last_pointer;
    auto details = Json::fromObject(_details);

    int err = GA_get_previous_addresses(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

GetAddressesHandler::GetAddressesHandler(int last_pointer, Account* account)
    : Handler(account->wallet()->session())
    , m_subaccount(account->pointer())
    , m_last_pointer(last_pointer)
{
}

QJsonArray GetAddressesHandler::addresses() const
{
    return result().value("result").toObject().value("list").toArray();
}

int GetAddressesHandler::lastPointer() const
{
    return result().value("result").toObject().value("last_pointer").toInt(1);
}
