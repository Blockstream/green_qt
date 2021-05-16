#ifndef GREEN_LOGINHANDLER_H
#define GREEN_LOGINHANDLER_H

#include "handler.h"

#include <QStringList>

class LoginHandler : public Handler
{
    Q_OBJECT
public:
    LoginHandler(Wallet* wallet, const QStringList& mnemonic);
    LoginHandler(Wallet* wallet, const QStringList& mnemonic, const QString& password);
    LoginHandler(Wallet* wallet, const QJsonObject& hw_device);
    LoginHandler(Wallet* wallet, const QJsonObject& pin_data, const QString& pin);
private:
    const QJsonObject m_hw_device{};
    const QJsonObject m_details{};
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
};

#endif // GREEN_LOGINHANDLER_H
