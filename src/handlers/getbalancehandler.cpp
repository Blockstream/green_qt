#include "account.h"
#include "getbalancehandler.h"
#include "json.h"

#include <gdk.h>

GetBalanceHandler::GetBalanceHandler(Account* account)
    : Handler(account->wallet())
    , m_account(account)
{
}

void GetBalanceHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto details = Json::fromObject({
        { "subaccount", m_account->m_pointer },
        { "num_confs", 0 }
    });

    int err = GA_get_balance(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}
