#include "createtransactionhandler.h"
#include "json.h"

#include <gdk.h>
#include <QDebug>


CreateTransactionHandler::CreateTransactionHandler(const QJsonObject& details, Session* session)
    : Handler(session)
    , m_details(details)
{
}

void CreateTransactionHandler::call(GA_session* session, GA_auth_handler** auth_handler) {
    qDebug() << Q_FUNC_INFO << m_details;

    auto details = Json::fromObject(m_details);
    int err = GA_create_transaction(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

