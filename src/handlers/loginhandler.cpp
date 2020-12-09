#include "json.h"
#include "loginhandler.h"

#include <gdk.h>

LoginHandler::LoginHandler(Wallet* wallet, const QStringList &mnemonic)
    : Handler(wallet)
    , m_mnemonic(mnemonic)
{
    Q_ASSERT(m_mnemonic.size() == 24);
}

LoginHandler::LoginHandler(Wallet* wallet, const QStringList& mnemonic, const QString& password)
    : Handler(wallet)
    , m_mnemonic(mnemonic)
    , m_password(password)
{
    Q_ASSERT((m_mnemonic.size() == 24 && m_password.isEmpty()) || (m_mnemonic.size() == 27 && !m_password.isEmpty()));
}

LoginHandler::LoginHandler(Wallet* wallet, const QJsonObject& device_details)
    : Handler(wallet)
    , m_device_details(device_details)
{
    // TODO: assert device_details or use Device instance to infer them
}

void LoginHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    QByteArray mnemonic = m_mnemonic.join(' ').toLocal8Bit();
    QByteArray password = m_password.toLocal8Bit();
    GA_json* device_details = Json::fromObject(m_device_details);
    int err = GA_login(session, device_details, mnemonic.constData(), password.constData(), auth_handler);
    Q_ASSERT(err == GA_OK);
    err = GA_destroy_json(device_details);
    Q_ASSERT(err == GA_OK);
}
