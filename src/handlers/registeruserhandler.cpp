#include "json.h"
#include "registeruserhandler.h"

#include <gdk.h>

RegisterUserHandler::RegisterUserHandler(const QStringList& mnemonic, Session* session)
    : Handler(session)
    , m_mnemonic(mnemonic)
{
    Q_ASSERT(m_mnemonic.size() == 12 || m_mnemonic.size() == 24 || m_mnemonic.size() == 27);
}

RegisterUserHandler::RegisterUserHandler(const QJsonObject& device_details, Session* session)
    : Handler(session)
    , m_device_details(device_details)
{
    // TODO: assert device_details or use Device instance to infer them
}

void RegisterUserHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    QByteArray mnemonic = m_mnemonic.join(' ').toLocal8Bit();
    auto device_details = Json::fromObject(m_device_details);
    int err = GA_register_user(session, device_details.get(), mnemonic.constData(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

QString RegisterUserHandler::walletHashId() const
{
    Q_ASSERT(result().value("status") == "done");
    const auto wallet_hash_id = result().value("result").toObject().value("wallet_hash_id").toString();
    Q_ASSERT(!wallet_hash_id.isEmpty());
    return wallet_hash_id;
}
