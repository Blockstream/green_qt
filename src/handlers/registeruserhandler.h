#ifndef GREEN_REGISTERUSERHANDLER_H
#define GREEN_REGISTERUSERHANDLER_H

#include "handler.h"

#include <QStringList>
#include <QJsonObject>

class RegisterUserHandler : public Handler
{
    Q_OBJECT
public:
    RegisterUserHandler(const QStringList& mnemonic, Session* session);
    RegisterUserHandler(const QJsonObject& device_details, Session* session);
    QString walletHashId() const;
private:
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
    const QJsonObject m_device_details;
};

#endif // GREEN_REGISTERUSERHANDLER_H
