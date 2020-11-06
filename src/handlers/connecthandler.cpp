#include "json.h"
#include "connecthandler.h"
#include "network.h"
#include "wallet.h"

#include <gdk.h>

namespace {
    QJsonObject get_wallet_params(Wallet* wallet)
    {
      const auto log_level = QString::fromLocal8Bit(qgetenv("GREEN_GDK_LOG_LEVEL"));
      return {
          { "name", wallet->network()->id() },
          { "log_level", log_level.isEmpty() ? "info" : log_level },
          { "use_tor", false },
      };
    }
} // namespace

ConnectHandler::ConnectHandler(Wallet* wallet)
    : Handler(wallet)
    , m_params(get_wallet_params(wallet))
{
}

void ConnectHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_UNUSED(auth_handler)
    auto params = Json::fromObject(m_params);
    int err = GA_connect(session, params);
    Q_ASSERT(err == GA_OK);
    err = GA_destroy_json(params);
    Q_ASSERT(err == GA_OK);
}
