#include "loginhandler.h"

#include <gdk.h>

LoginHandler::LoginHandler(Wallet *wallet, const QStringList &mnemonic, const QString &password)
    : Handler(wallet)
    , m_mnemonic(mnemonic)
    , m_password(password)
{
    Q_ASSERT(m_mnemonic.size() == 24 || (m_mnemonic.size() == 27 && !m_password.isEmpty()));
}

void LoginHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    QByteArray mnemonic = m_mnemonic.join(' ').toLocal8Bit();
    QByteArray password = m_password.toLocal8Bit();
    GA_json* device;
    int err = GA_convert_string_to_json("{}", &device);
    Q_ASSERT(err == GA_OK);
    err = GA_login(session, device, mnemonic.constData(), password.constData(), auth_handler);
    Q_ASSERT(err == GA_OK);
    err = GA_destroy_json(device);
    Q_ASSERT(err == GA_OK);
}
