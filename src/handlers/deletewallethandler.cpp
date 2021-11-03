#include "deletewallethandler.h"

#include <gdk.h>

DeleteWalletHandler::DeleteWalletHandler(Session* session)
    : Handler(session)
{
}

void DeleteWalletHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    int res = GA_remove_account(session, auth_handler);
    Q_ASSERT(res == GA_OK);
}
