#include "util.h"

#include <QDir>
#include <QCryptographicHash>

QString g_data_location;

QString GetDataDir(const QString& context)
{
    Q_ASSERT(!g_data_location.isEmpty());
    const QString path = g_data_location + QDir::separator() + context;
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

QByteArray ReverseByteArray(const QByteArray& byte_array)
{
    QByteArray result;
    result.reserve(byte_array.size());
    for (int i = byte_array.size() - 1; i >= 0; --i) {
        result.append(byte_array[i]);
    }
    return result;
}

QString Sha256(const QString &value)
{
    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(value.toLocal8Bit());
    return QString::fromLocal8Bit(hash.result().toHex());
}
