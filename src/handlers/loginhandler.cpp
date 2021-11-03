#include "json.h"
#include "loginhandler.h"

#include <gdk.h>

LoginHandler::LoginHandler(const QStringList& mnemonic, Session* session)
    : Handler(session)
    , m_details({
        { "mnemonic", mnemonic.join(' ') },
        { "password", "" }
    })
{
    Q_ASSERT(mnemonic.size() == 12 || mnemonic.size() == 24);
}

LoginHandler::LoginHandler(const QStringList& mnemonic, const QString& password, Session* session)
    : Handler(session)
    , m_details({
        { "mnemonic", mnemonic.join(' ') },
        { "password", password }
    })
{
    Q_ASSERT((mnemonic.size() == 12 && password.isEmpty()) || (mnemonic.size() == 24 && password.isEmpty()) || (mnemonic.size() == 27 && !password.isEmpty()));
}

LoginHandler::LoginHandler(const QJsonObject& hw_device, Session* session)
    : Handler(session)
    , m_hw_device(hw_device)
{
}

LoginHandler::LoginHandler(const QJsonObject& pin_data, const QString& pin, Session* session)
    : Handler(session)
    , m_details({
        { "pin", pin },
        { "pin_data", pin_data }
    })
{
}

LoginHandler::LoginHandler(const QString& username, const QString& password, Session* session)
    : Handler(session)
    , m_details({
        { "username", username },
        { "password", password }
    })
{
}

void LoginHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    auto hw_device = Json::fromObject(m_hw_device);
    auto details = Json::fromObject(m_details);
    GA_login_user(session, hw_device.get(), details.get(), auth_handler);
}

QString LoginHandler::walletHashId() const
{
    Q_ASSERT(result().value("status") == "done");
    const auto wallet_hash_id = result().value("result").toObject().value("wallet_hash_id").toString();
    Q_ASSERT(!wallet_hash_id.isEmpty());
    return wallet_hash_id;
}
