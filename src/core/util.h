#ifndef BLOCKSTREAM_CORE_UTIL_H
#define BLOCKSTREAM_CORE_UTIL_H

#include <QByteArray>
#include <QCommandLineParser>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QString>

extern QString g_data_location;
extern QCommandLineParser g_args;

bool ExistsDataDir(const QString& context);
bool RemoveDataDir(const QString& context);
QString GetDataDir(const QString& context);
QString GetDataFile(const QString& context, const QString& name);
QString GetLogFilename();

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

bool IsSupportedPaymentUrl(const QString& url);

QString GetPlatformName();

bool IsRunningAsFlatpak();

void ShowApplication();

#endif // BLOCKSTREAM_CORE_UTIL_H
