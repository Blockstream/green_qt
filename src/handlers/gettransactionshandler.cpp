#include "json.h"
#include "gettransactionshandler.h"

#include <gdk.h>

void GetTransactionsHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    auto details = Json::fromObject({
        { "subaccount", m_subaccount },
        { "first", m_first },
        { "count", m_count }
    });

    int err = GA_get_transactions(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

GetTransactionsHandler::GetTransactionsHandler(int subaccount, int first, int count, Wallet *wallet)
    : Handler(wallet)
    , m_subaccount(subaccount)
    , m_first(first)
    , m_count(count)
{
}

QJsonArray GetTransactionsHandler::transactions() const
{
    return result().value("result").toObject().value("transactions").toArray();
}
