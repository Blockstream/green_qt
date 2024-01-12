#include "util.h"

#include <QCryptographicHash>
#include <QDir>

#ifdef Q_OS_MACOS
#include <sys/sysctl.h>
#include <sys/types.h>
#endif

#ifdef Q_OS_WIN
#include <windows.h>
#include <winreg.h>
#endif

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
    return value.toInteger();
}

QVector<uint32_t> ParsePath(const QJsonValue &value)
{
    return ParsePath(value.toArray());
}

QVector<uint32_t> ParsePath(const QJsonArray &array)
{
    QVector<uint32_t> path;
    for (const auto value : array) {
        path.append(value.toInteger());
    }
    return path;
}

quint32 ParseLocktime(const QJsonValue &value)
{
    return value.toInteger();
}

quint32 ParseSequence(const QJsonValue &value)
{
    return value.toInteger(0);
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

QString GetHardwareModel()
{
    static QString hardware_model;
    if (hardware_model.isEmpty()) {
#ifdef Q_OS_MACOS
        size_t len = 0;
        sysctlbyname("hw.model", NULL, &len, NULL, 0);
        if (len) {
            char* model = (char*) malloc(len * sizeof(char));
            sysctlbyname("hw.model", model, &len, NULL, 0);
            hardware_model = QString::fromLocal8Bit(model, len);
            free(model);
        }
#endif

#ifdef Q_OS_LINUX
        QFile file("/sys/class/dmi/id/product_name");
        if (file.open(QFile::ReadOnly)) {
            hardware_model = QString::fromUtf8(file.readAll());
            file.close();
        }
#endif

#ifdef Q_OS_WIN
        HKEY handle_key;
        char buffer[255] = { 0 };
        DWORD size = sizeof(buffer);
        try {
            if (RegOpenKey(HKEY_LOCAL_MACHINE, TEXT("HARDWARE\\DESCRIPTION\\System\\BIOS"), &handle_key) == ERROR_SUCCESS) {
                if (RegQueryValueEx(handle_key, TEXT("SystemProductName"), NULL, NULL, (LPBYTE)buffer, &size) == ERROR_SUCCESS) {
                    hardware_model = QString::fromWCharArray((WCHAR*) buffer, size / sizeof(WCHAR));
                }
                RegCloseKey(handle_key);
            }
        } catch (...) {}
#endif
        hardware_model = hardware_model.trimmed();
    }
    return hardware_model;
}
