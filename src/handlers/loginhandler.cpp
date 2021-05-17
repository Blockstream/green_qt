#include "json.h"
#include "loginhandler.h"

#include <gdk.h>

LoginHandler::LoginHandler(Wallet* wallet, const QStringList &mnemonic)
    : Handler(wallet)
    , m_details({
        { "mnemonic", mnemonic.join(' ') },
        { "password", "" }
    })
{
    Q_ASSERT(mnemonic.size() == 24);
}

LoginHandler::LoginHandler(Wallet* wallet, const QStringList& mnemonic, const QString& password)
    : Handler(wallet)
    , m_details({
        { "mnemonic", mnemonic.join(' ') },
        { "password", password }
    })
{
    Q_ASSERT((mnemonic.size() == 24 && password.isEmpty()) || (mnemonic.size() == 27 && !password.isEmpty()));
}

LoginHandler::LoginHandler(Wallet* wallet, const QJsonObject& hw_device)
    : Handler(wallet)
    , m_hw_device(hw_device)
{
}

LoginHandler::LoginHandler(Wallet *wallet, const QJsonObject &pin_data, const QString &pin)
    : Handler(wallet)
    , m_details({
        { "pin", pin },
        { "pin_data", pin_data }
    })
{
}

LoginHandler::LoginHandler(Wallet *wallet, const QString &username, const QString &password)
    : Handler(wallet)
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
    int err = GA_login_user(session, hw_device.get(), details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

QString LoginHandler::walletHashId() const
{
    Q_ASSERT(result().value("status") == "done");
    const auto wallet_hash_id = result().value("result").toObject().value("wallet_hash_id").toString();
    Q_ASSERT(!wallet_hash_id.isEmpty());
    return wallet_hash_id;
}
