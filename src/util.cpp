#include "util.h"

#include <QDir>
#include <QStandardPaths>

QString GetDataDir(const QString& context)
{
    const QString path = QStandardPaths::writableLocation(QStandardPaths::DataLocation) + QDir::separator() + context;
    const QDir dir;
    const bool created = dir.mkpath(path);
    Q_ASSERT(created);
    return path;
}

QString GetDataFile(const QString& context, const QString& name)
{
    return GetDataDir(context) + QDir::separator() + name;
}

quint64 ParseSatoshi(const QJsonValue &value)
{
    return value.toDouble();
}

QVector<uint32_t> ParsePath(const QJsonValue &value)
{
    return ParsePath(value.toArray());
}

QVector<uint32_t> ParsePath(const QJsonArray &array)
{
    QVector<uint32_t> path;
    for (const auto value : array) {
        path.append(value.toDouble());
    }
    return path;
}

quint32 ParseLocktime(const QJsonValue &value)
{
    return value.toDouble();
}

quint32 ParseSequence(const QJsonValue &value)
{
    return value.toDouble();
}

QByteArray ParseByteArray(const QJsonValue &value)
{
    return QByteArray::fromHex(value.toString().toLocal8Bit());
}
