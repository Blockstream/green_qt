#include "ga.h"
#include "json.h"
#include <gdk.h>

namespace gdk {

QJsonObject convert_amount(GA_session* session, const QJsonObject& input)
{
    auto value_details = Json::fromObject(input);
    GA_json* output;
    int err = GA_convert_amount(session, value_details.get(), &output);
    if (err != GA_OK) return {};
    auto value = Json::toObject(output);
    GA_destroy_json(output);
    return value;
}

QStringList generate_mnemonic(int size)
{
    Q_ASSERT(size == 12 || size == 24);

    char* mnemonic;
    int err = size == 12 ? GA_generate_mnemonic_12(&mnemonic) : GA_generate_mnemonic(&mnemonic);
    Q_ASSERT(err == GA_OK);
    auto result = QString(mnemonic).split(' ');
    GA_destroy_string(mnemonic);
    return result;
}

QJsonObject get_settings(GA_session* session)
{
    GA_json* settings;
    int err = GA_get_settings(session, &settings);
    Q_ASSERT(err == GA_OK);
    auto result = Json::toObject(settings);
    GA_destroy_json(settings);
    return result;
}

QJsonObject get_twofactor_config(GA_session* session)
{
    GA_json* config;
    int err = GA_get_twofactor_config(session, &config);
    Q_ASSERT(err == GA_OK);
    auto result = Json::toObject(config);
    GA_destroy_json(config);
    return result;
}

} // namespace GA
