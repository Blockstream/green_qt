#include "json.h"

#include <gdk.h>
#include <memory>
#include <nlohmann/json.hpp>

#include <QJsonDocument>

namespace Json {

void Destructor::operator()(GA_json* json)
{
    int res = GA_destroy_json(json);
    Q_ASSERT(res == GA_OK);
}

namespace {

QJsonValue nlohmann_to_qt(const nlohmann::json& json)
{
    if (json.is_object()) {
        QJsonObject object;
        for (auto& [key, val] : json.items()) {
            object[QString::fromStdString(key)] = nlohmann_to_qt(val);
        }
        return object;
    }
    if (json.is_string()) {
        return QString::fromStdString(json.get<std::string>());
    }
    if (json.is_number_unsigned()) {
        const auto uv = json.get<quint64>();
        const auto sv = json.get<qint64>();
        Q_ASSERT(uv == static_cast<quint64>(sv));
        return sv;
    }
    if (json.is_number_integer()) {
        return json.get<qint64>();
    }
    if (json.is_number_float()) {
        return json.get<double>();
    }
    if (json.is_boolean()) {
        return json.get<bool>();
    }
    if (json.is_array()) {
        QJsonArray array;
        for (auto& it : json) {
            array.append(nlohmann_to_qt(it));
        }
        return array;
    }
    if (json.is_null()) {
        return QJsonValue::Null;
    }
    Q_UNREACHABLE();
}

} // namespace

QJsonArray toArray(const GA_json* json)
{
    auto result = nlohmann_to_qt(*(const nlohmann::json*) json);
    Q_ASSERT(result.isArray());
    return result.toArray();
}

QJsonObject toObject(const GA_json* json)
{
    auto result = nlohmann_to_qt(*(const nlohmann::json*) json);
    Q_ASSERT(result.isObject() || result.isNull());
    return result.toObject();
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

QByteArray jsonToString(const GA_json* json)
{
    char* str;
    int err = GA_convert_json_to_string(json, &str);
    Q_ASSERT(err == GA_OK);
    QByteArray string(str);
    GA_destroy_string(str);
    return string;
}


} // namespace Json



