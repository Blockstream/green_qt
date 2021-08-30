#ifndef GREEN_GETADDRESSESHANDLER_H
#define GREEN_GETADDRESSESHANDLER_H

#include "handler.h"

QT_FORWARD_DECLARE_CLASS(Account)

class GetAddressesHandler : public Handler
{
    const quint32 m_subaccount;
    int m_last_pointer = 0;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    GetAddressesHandler(int last_pointer, Account* account);
    QJsonArray addresses() const;
    int lastPointer() const;
};

#endif // GREEN_GETADDRESSESHANDLER_H
