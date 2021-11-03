#include "json.h"
#include "updateaccounthandler.h"

#include <gdk.h>

UpdateAccountHandler::UpdateAccountHandler(const QJsonObject &details, Session* session)
    : Handler(session)
    , m_details(details)
{
}

void UpdateAccountHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    auto details = Json::fromObject(m_details);
    int err = GA_update_subaccount(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}
