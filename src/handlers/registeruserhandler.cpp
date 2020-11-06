#include "json.h"
#include "registeruserhandler.h"

#include <gdk.h>

RegisterUserHandler::RegisterUserHandler(Wallet* wallet, const QStringList& mnemonic)
    : Handler(wallet)
    , m_mnemonic(mnemonic)
{
    Q_ASSERT(m_mnemonic.size() == 24 || m_mnemonic.size() == 27);
}

RegisterUserHandler::RegisterUserHandler(Wallet* wallet, const QJsonObject& device_details)
    : Handler(wallet)
    , m_device_details(device_details)
{
    // TODO: assert device_details or use Device instance to infer them
}

void RegisterUserHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    QByteArray mnemonic = m_mnemonic.join(' ').toLocal8Bit();
    GA_json* device_details = Json::fromObject(m_device_details);
    int err = GA_register_user(session, device_details, mnemonic.constData(), auth_handler);
    Q_ASSERT(err == GA_OK);
    err = GA_destroy_json(device_details);
    Q_ASSERT(err == GA_OK);
}
