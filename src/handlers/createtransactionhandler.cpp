#include "createtransactionhandler.h"
#include "json.h"

#include <gdk.h>

CreateTransactionHandler::CreateTransactionHandler(Wallet* wallet, const QJsonObject& details)
    : Handler(wallet)
    , m_details(details)
{
}

void CreateTransactionHandler::call(GA_session* session, GA_auth_handler** auth_handler) {
    auto details = Json::fromObject(m_details);
    int err = GA_create_transaction(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

