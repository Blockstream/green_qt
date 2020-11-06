#ifndef GREEN_LOGINHANDLER_H
#define GREEN_LOGINHANDLER_H

#include "handler.h"

#include <QStringList>

class LoginHandler : public Handler
{
    Q_OBJECT
public:
    LoginHandler(Wallet* wallet, const QStringList& mnemonic, const QString& password = {});
private:
    const QStringList m_mnemonic;
    const QString m_password;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
};

#endif // GREEN_LOGINHANDLER_H
