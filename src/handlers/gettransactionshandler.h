#ifndef GREEN_GETTRANSACTIONHANDLER_H
#define GREEN_GETTRANSACTIONHANDLER_H

#include "handler.h"

class GetTransactionsHandler : public Handler
{
    int m_subaccount;
    int m_first;
    int m_count;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    GetTransactionsHandler(int subaccount, int first, int count, Wallet *wallet);
};

#endif // GREEN_GETTRANSACTIONHANDLER_H
