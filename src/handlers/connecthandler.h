#ifndef GREEN_CONNECTHANDLER_H
#define GREEN_CONNECTHANDLER_H

#include "handler.h"

class ConnectHandler : public Handler
{
    Q_OBJECT
public:
    ConnectHandler(Wallet* wallet);
    ConnectHandler(Wallet* wallet, const QString& proxy, bool use_tor);
private:
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_params;
};

#endif // GREEN_CONNECTHANDLER_H
