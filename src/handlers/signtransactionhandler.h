#ifndef GREEN_SIGNTRANSACTIONHANDLER_H
#define GREEN_SIGNTRANSACTIONHANDLER_H

#include "handler.h"

class SignTransactionHandler : public Handler
{
    const QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    SignTransactionHandler(Wallet *wallet, const QJsonObject& details);
};

#endif // GREEN_SIGNTRANSACTIONHANDLER_H
