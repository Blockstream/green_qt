#include "ga.h"
#include "json.h"
#include <gdk.h>

#include <QDebug>

namespace GA {

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
