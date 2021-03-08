#include "json.h"
#include "getaddresseshandler.h"

#include <gdk.h>

void GetAddressesHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    auto details = Json::fromObject({
        { "subaccount", m_subaccount },
        { "last_pointer", m_last_pointer }
    });

    int err = GA_get_previous_addresses(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

GetAddressesHandler::GetAddressesHandler(int subaccount, int last_pointer, Wallet *wallet)
    : Handler(wallet)
    , m_subaccount(subaccount)
    , m_last_pointer(last_pointer)
{
}

QJsonArray GetAddressesHandler::addresses() const
{
    return result().value("result").toObject().value("list").toArray();
}

int GetAddressesHandler::lastPointer() const
{
    return result().value("result").toObject().value("last_pointer").toInt();
}
