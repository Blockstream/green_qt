#ifndef GREEN_GETBALANCEHANDLER_H
#define GREEN_GETBALANCEHANDLER_H

#include "handler.h"

class GetBalanceHandler : public Handler
{
    Account* const m_account;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    GetBalanceHandler(Account* account);
};

#endif // GREEN_GETBALANCEHANDLER_H
