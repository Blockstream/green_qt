#include "json.h"

#include <memory>
#include <gdk.h>

#include <QJsonDocument>

namespace Json {

void Destructor::operator()(GA_json* json)
{
    int res = GA_destroy_json(json);
    Q_ASSERT(res == GA_OK);
}

namespace {

QJsonDocument doc(const GA_json* json)
{
    Q_ASSERT(json);
    char* string;
    GA_convert_json_to_string(json, &string);
    auto document = QJsonDocument::fromJson(string);
    GA_destroy_string(string);
    return document;
}

} // namespace

QJsonArray toArray(const GA_json* json)
{
    return doc(json).array();
}

QJsonObject toObject(const GA_json *json)
{
    return doc(json).object();
}

std::unique_ptr<GA_json, Destructor> fromObject(const QJsonObject& object)
{
    return stringToJson(QJsonDocument(object).toJson());
}

std::unique_ptr<GA_json, Destructor> stringToJson(const QByteArray& string)
{
    GA_json* json;
    GA_convert_string_to_json(string, &json);
    return std::unique_ptr<GA_json, Destructor>(json);
}

QByteArray toByteArray(const GA_json* json)
{
    char* str;
    int err = GA_convert_json_to_string(json, &str);
    Q_ASSERT(err == GA_OK);
    QByteArray bytearray(str);
    GA_destroy_string(str);
    return bytearray;
}


} // namespace Json



