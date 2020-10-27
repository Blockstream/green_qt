#ifndef GREEN_UTIL_H
#define GREEN_UTIL_H

#include <QByteArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>
#include <QString>

QString GetDataDir(const QString& context);
QString GetDataFile(const QString& context, const QString& name);

QVector<uint32_t> ParsePath(const QJsonArray& array);
QVector<uint32_t> ParsePath(const QJsonValue& value);
quint32 ParseLocktime(const QJsonValue& value);
quint64 ParseSatoshi(const QJsonValue& value);
quint32 ParseSequence(const QJsonValue& value);
QByteArray ParseByteArray(const QJsonValue& value);

#endif // GREEN_UTIL_H
