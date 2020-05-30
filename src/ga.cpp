#include "ga.h"
#include "json.h"
#include <gdk.h>

#include <QDebug>

namespace GA {

int reconnect_hint(GA_session* session, const QJsonObject& data)
{
    GA_json* hint = Json::fromObject(data);
    int err = GA_reconnect_hint(session, hint);
    GA_destroy_json(hint);
    return err;
}

int connect(GA_session* session, const QJsonObject& data)
{
    GA_json* net_params = Json::fromObject(data);
    int err = GA_connect(session, net_params);
    GA_destroy_json(net_params);
    return err;
}

QJsonObject auth_handler_get_result(GA_auth_handler* call)
{
    GA_json* output;
    int err = GA_auth_handler_get_status(call, &output);
    Q_ASSERT(err == GA_OK);
    auto result = Json::toObject(output);
    GA_destroy_json(output);
    return result;
}

void destroy_auth_handler(GA_auth_handler* call)
{
    int err = GA_destroy_auth_handler(call);
    Q_ASSERT(err == GA_OK);
}

QJsonArray get_subaccounts(GA_session* session)
{
    Q_ASSERT(session);
    auto result = process_auth([&] (GA_auth_handler** call) {
        int err = GA_get_subaccounts(session, call);
        Q_ASSERT(err == GA_OK);
    });
    Q_ASSERT(result.value("status").toString() == "done");
    return result.value("result").toObject().value("subaccounts").toArray();
}

QJsonObject convert_amount(GA_session* session, const QJsonObject& input)
{
    GA_json* value_details = Json::fromObject(input);
    GA_json* output;
    int err = GA_convert_amount(session, value_details, &output);
    GA_destroy_json(value_details);
    if (err != GA_OK) return {};
    auto value = Json::toObject(output);
    GA_destroy_json(output);
    return value;
}

QJsonObject process_auth2(GA_auth_handler* call)
{
    while (true) {
        QJsonObject result = GA::auth_handler_get_result(call);
        QString status = result.value("status").toString();

        if (status == "done") {
            return result;
        }

        if (status == "error") {
            return result;
        }

        if (status == "request_code") {
            Q_UNREACHABLE();
        }

        if (status == "resolve_code") {
            Q_UNREACHABLE();
        }

        if (status == "call") {
            GA_auth_handler_call(call);
        }
    }
    Q_UNREACHABLE();
}

} // namespace GA
