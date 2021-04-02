#ifndef GREEN_UPDATEACCOUNTHANDLER_H
#define GREEN_UPDATEACCOUNTHANDLER_H

#include "handler.h"

class UpdateAccountHandler : public Handler
{
    const QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler);
public:
    UpdateAccountHandler(Wallet* wallet, const QJsonObject& details);
};

#endif // GREEN_UPDATEACCOUNTHANDLER_H
