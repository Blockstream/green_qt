#ifndef GREEN_GETADDRESSESHANDLER_H
#define GREEN_GETADDRESSESHANDLER_H

#include "handler.h"

class GetAddressesHandler : public Handler
{
    int m_subaccount;
    int m_last_pointer = 0;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    GetAddressesHandler(int subaccount, int last_pointer, Wallet *wallet);
    QJsonArray addresses() const;
    int lastPointer() const;
};

#endif // GREEN_GETADDRESSESHANDLER_H
