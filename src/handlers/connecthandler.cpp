#include "json.h"
#include "connecthandler.h"
#include "network.h"
#include "wallet.h"

#include <gdk.h>

namespace {
    QJsonObject get_wallet_params(Wallet* wallet, const QString& proxy, bool use_tor)
    {
        const auto log_level = QString::fromLocal8Bit(qgetenv("GREEN_GDK_LOG_LEVEL"));
        QJsonObject params = {
            { "name", wallet->network()->id() },
            { "log_level", log_level.isEmpty() ? "info" : log_level },
            { "use_tor", use_tor },
        };
        if (!proxy.isEmpty()) params.insert("proxy", proxy);
        return params;
    }
} // namespace

ConnectHandler::ConnectHandler(Wallet* wallet)
    : Handler(wallet)
    , m_params(get_wallet_params(wallet, {}, false))
{
}

ConnectHandler::ConnectHandler(Wallet* wallet, const QString& proxy, bool use_tor)
    : Handler(wallet)
    , m_params(get_wallet_params(wallet, proxy, use_tor))
{
}

void ConnectHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_UNUSED(auth_handler)
    auto params = Json::fromObject(m_params);
    int err = GA_connect(session, params);
    GA_destroy_json(params);
    if (err != GA_OK) {
        emit error();
        return;
    }
    auto hint = Json::fromObject({{ "hint", "now" }});
    err = GA_reconnect_hint(session, hint);
    Q_ASSERT(err == GA_OK);
    err = GA_destroy_json(hint);
    Q_ASSERT(err == GA_OK);
}
