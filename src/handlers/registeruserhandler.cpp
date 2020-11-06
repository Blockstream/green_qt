#include "registeruserhandler.h"

#include <gdk.h>

RegisterUserHandler::RegisterUserHandler(Wallet* wallet, const QStringList& mnemonic)
    : Handler(wallet)
    , m_mnemonic(mnemonic)
{
    Q_ASSERT(m_mnemonic.size() == 24 || m_mnemonic.size() == 27);
}

void RegisterUserHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    QByteArray mnemonic = m_mnemonic.join(' ').toLocal8Bit();
    GA_json* device;
    int err = GA_convert_string_to_json("{}", &device);
    Q_ASSERT(err == GA_OK);
    err = GA_register_user(session, device, mnemonic.constData(), auth_handler);
    Q_ASSERT(err == GA_OK);
    err = GA_destroy_json(device);
    Q_ASSERT(err == GA_OK);
}
