#ifndef GREEN_CREATEACCOUNTHANDLER_H
#define GREEN_CREATEACCOUNTHANDLER_H

#include "handler.h"

class CreateAccountHandler : public Handler
{
    QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    CreateAccountHandler(const QJsonObject& details, Wallet* wallet);
    int pointer() const;
};

#endif // GREEN_CREATEACCOUNTHANDLER_H
