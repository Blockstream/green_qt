#ifndef GREEN_JSON_H
#define GREEN_JSON_H

#include <QJsonArray>
#include <QJsonObject>

struct GA_json;

namespace Json {

QJsonArray toArray(const GA_json* json);
QJsonObject toObject(const GA_json* json);

GA_json* fromArray(const QJsonArray& array);
GA_json* fromObject(const QJsonObject& object);

QByteArray toByteArray(const GA_json* json);

} // namespace Json

#endif // GREEN_JSON_H
