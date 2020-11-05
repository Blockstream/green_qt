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

QStringList generate_mnemonic()
{
    char* mnemonic;
    int err = GA_generate_mnemonic(&mnemonic);
    Q_ASSERT(err == GA_OK);
    auto result = QString(mnemonic).split(' ');
    GA_destroy_string(mnemonic);
    return result;
}

} // namespace GA
