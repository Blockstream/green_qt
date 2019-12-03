#include "json.h"

#include <gdk.h>

#include <QJsonDocument>

namespace Json {

namespace {

QJsonDocument doc(const GA_json* json)
{
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

GA_json* fromArray(const QJsonArray& array)
{
    GA_json* json;
    GA_convert_string_to_json(QJsonDocument(array).toJson().constData(), &json);
    return json;
}

GA_json* fromObject(const QJsonObject& object)
{
    GA_json* json;
    GA_convert_string_to_json(QJsonDocument(object).toJson().constData(), &json);
    return json;
}


} // namespace Json



