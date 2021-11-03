#ifndef GREEN_LOGINHANDLER_H
#define GREEN_LOGINHANDLER_H

#include "handler.h"

#include <QStringList>

class LoginHandler : public Handler
{
    Q_OBJECT
public:
    LoginHandler(const QStringList& mnemonic, Session* session);
    LoginHandler(const QStringList& mnemonic, const QString& password, Session* session);
    LoginHandler(const QJsonObject& hw_device, Session* session);
    LoginHandler(const QJsonObject& pin_data, const QString& pin, Session* session);
    LoginHandler(const QString& username, const QString& password, Session* session);
    QString walletHashId() const;
private:
    const QJsonObject m_hw_device{};
    const QJsonObject m_details{};
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
};

#endif // GREEN_LOGINHANDLER_H
