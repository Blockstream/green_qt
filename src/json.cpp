#include "json.h"

#include <gdk.h>

#include <QJsonDocument>

#include <memory>
#include <string>

namespace Json {

namespace {

QByteArray convertToString(const GA_json* json)
{
    char* output = nullptr;
    if (GA_convert_json_to_string(json, &output) != GA_OK) {
        return {};
    }
    QByteArray result(output);
    GA_destroy_string(output);
    return result;
}

} // namespace

void Destructor::operator()(GA_json* json)
{
    int res = GA_destroy_json(json);
    Q_ASSERT(res == GA_OK);
}

QJsonArray toArray(const GA_json* json)
{
    return QJsonDocument::fromJson(convertToString(json)).array();
}

QJsonObject toObject(const GA_json* json)
{
    return QJsonDocument::fromJson(convertToString(json)).object();
}

std::unique_ptr<GA_json, Destructor> fromObject(const QJsonObject& object)
{
    return stringToJson(QJsonDocument(object).toJson());
}

std::unique_ptr<GA_json, Destructor> stringToJson(const QByteArray& string)
{
    GA_json* json = nullptr;
    if (GA_convert_string_to_json(string, &json) != GA_OK) {
        return {};
    }
    return std::unique_ptr<GA_json, Destructor>(json);
}

QByteArray jsonToString(const GA_json* json)
{
    return convertToString(json);
}

} // namespace Json
