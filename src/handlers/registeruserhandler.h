#ifndef GREEN_REGISTERUSERHANDLER_H
#define GREEN_REGISTERUSERHANDLER_H

#include "handler.h"

#include <QStringList>

class RegisterUserHandler : public Handler
{
    Q_OBJECT
public:
    RegisterUserHandler(Wallet* wallet, const QStringList& mnemonic);
private:
    const QStringList m_mnemonic;
private:
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
};

#endif // GREEN_REGISTERUSERHANDLER_H
