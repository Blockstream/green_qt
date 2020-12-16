#ifndef GREEN_JSON_H
#define GREEN_JSON_H

#include <QJsonArray>
#include <QJsonObject>

#include <memory>

struct GA_json;

namespace Json {

struct Destructor {
    void operator()(GA_json* json);
};

QJsonArray toArray(const GA_json* json);
QJsonObject toObject(const GA_json* json);
std::unique_ptr<GA_json, Destructor> fromObject(const QJsonObject& object);
std::unique_ptr<GA_json, Destructor> stringToJson(const QByteArray& string);
QByteArray jsonToString(const GA_json* json);

} // namespace Json

#endif // GREEN_JSON_H
