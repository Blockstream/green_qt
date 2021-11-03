#include "json.h"
#include "signtransactionhandler.h"

#include <gdk.h>

SignTransactionHandler::SignTransactionHandler(const QJsonObject& details, Session *session)
    : Handler(session)
    , m_details(details)
{
}

void SignTransactionHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto details = Json::fromObject(m_details);
    int err = GA_sign_transaction(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}
