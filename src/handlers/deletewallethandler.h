#ifndef GREEN_DELETEWALLETHANDLER_H
#define GREEN_DELETEWALLETHANDLER_H

#include "handler.h"

class DeleteWalletHandler : public Handler
{
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    DeleteWalletHandler(Wallet* wallet);
};

#endif // GREEN_DELETEWALLETHANDLER_H
