#ifndef GREEN_UTIL_H
#define GREEN_UTIL_H

#include <QByteArray>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QString>

bool ExistsDataDir(const QString& context);
QString GetDataDir(const QString& context);
QString GetDataFile(const QString& context, const QString& name);

QVector<uint32_t> ParsePath(const QJsonArray& array);
QVector<uint32_t> ParsePath(const QJsonValue& value);
quint32 ParseLocktime(const QJsonValue& value);
quint64 ParseSatoshi(const QJsonValue& value);
quint32 ParseSequence(const QJsonValue& value);
QByteArray ParseByteArray(const QJsonValue& value);

QByteArray ReverseByteArray(const QByteArray& byte_array);

QString Sha256(const QString& value);
QString Sha256(const QJsonObject& value);

QString GetHardwareModel();

#endif // GREEN_UTIL_H
