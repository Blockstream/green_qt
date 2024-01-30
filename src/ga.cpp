#include "ga.h"

#include <gdk.h>

#include "config.h"
#include "json.h"
#include "util.h"

namespace gdk {

void init(const QCommandLineParser& args)
{
    const bool is_production = QStringLiteral("Production") == GREEN_ENV;
    const auto log_level = !is_production && args.isSet("debug") ? QStringLiteral("debug") : qEnvironmentVariable("GREEN_GDK_LOG_LEVEL", "info");

    auto config = Json::fromObject({
        { "datadir", GetDataDir("gdk") },
        { "log_level", log_level },
    });
    GA_init(config.get());
}

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
    if (err != GA_OK) return {};
    auto result = Json::toObject(config);
    GA_destroy_json(config);
    return result;
}

QJsonObject get_available_currencies(GA_session* session)
{
    GA_json* currencies;
    int err = GA_get_available_currencies(session, &currencies);
    if (err != GA_OK) return {};
    auto result = Json::toObject(currencies);
    GA_destroy_json(currencies);
    return result;
}

QJsonArray get_fee_estimates(GA_session* session)
{
    GA_json* estimates;
    int err = GA_get_fee_estimates(session, &estimates);
    if (err != GA_OK) return {};
    const auto fees = Json::toObject(estimates).value("fees").toArray();
    GA_destroy_json(estimates);
    return fees;
}

QJsonObject get_thread_error_details()
{
    GA_json* output;
    const auto rc = GA_get_thread_error_details(&output);
    if (rc != GA_OK) return {};
    const auto error = Json::toObject(output);
    GA_destroy_json(output);
    return error;
}

} // namespace gdk
