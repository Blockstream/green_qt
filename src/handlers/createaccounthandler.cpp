#include "createaccounthandler.h"
#include "json.h"

#include <gdk.h>

CreateAccountHandler::CreateAccountHandler(const QJsonObject &details, Session* session)
    : Handler(session)
    , m_details(details)
{
}

int CreateAccountHandler::pointer() const
{
    Q_ASSERT(result().value("status").toString() == "done");
    return result().value("result").toObject().value("pointer").toInt();
}

void CreateAccountHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    auto details = Json::fromObject(m_details);
    int res = GA_create_subaccount(session, details.get(), auth_handler);
    Q_ASSERT(res == GA_OK);
}

