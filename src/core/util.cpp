#include "config.h"
#include "util.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QIODevice>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QSet>
#include <QUrl>

#include <functional>

#ifdef Q_OS_MACOS
#include <sys/sysctl.h>
#include <sys/types.h>

#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>
#endif

#ifdef Q_OS_WIN
#include <windows.h>
#include <winreg.h>
#endif

QString g_data_location;
QCommandLineParser g_args;

bool ExistsDataDir(const QString& context)
{
    Q_ASSERT(!g_data_location.isEmpty());
    const QString path = g_data_location + QDir::separator() + context;
    const QDir dir(path);
    return dir.exists();
}

bool RemoveDataDir(const QString& context)
{
    Q_ASSERT(!g_data_location.isEmpty());
    QDir dir(g_data_location + QDir::separator() + context);
    if (!dir.exists()) return true;
    return dir.removeRecursively();
}

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

QString GetLogFilename()
{
    const QString log_file(GREEN_LOG_FILE);
    const QString version(GREEN_VERSION);

    return GetDataFile("logs", QString("%1.txt").arg(log_file.isEmpty() ? version : log_file));
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

QString Sha256(const QJsonObject& value)
{
    return Sha256(QJsonDocument(value).toJson(QJsonDocument::Compact));
}

static void ReplaceMatches(QString& text, const QRegularExpression& re, const std::function<QString(const QString&)>& replacement)
{
    QString result;
    qsizetype last = 0;
    for (auto it = re.globalMatch(text); it.hasNext();) {
        const auto match = it.next();
        result += QStringView(text).mid(last, match.capturedStart() - last);
        result += replacement(match.captured());
        last = match.capturedEnd();
    }
    if (last == 0) return;
    result += QStringView(text).mid(last);
    text = result;
}

bool RedactLog(QIODevice& in, QIODevice& out)
{
    static const QRegularExpression hex_re(R"(\b[0-9a-f]{32,}\b)");
    static const QRegularExpression public_re(R"((?:genesis_hash|policy_asset|block_hash|previous_hash|prev_blockhash|merkle_root)\W+(?:String\(\W*)?([0-9a-f]{64})|(?:tip=|block:)\(\d+, (?:Bitcoin|Elements)\(([0-9a-f]{64}))");
    static const QRegularExpression address_re(R"(address\\?"\s*:\s*(?:String\(\\?"|")([^\\"]+))");
    static const QRegularExpression fingerprint_re(R"((?:set_fingerprint input "String\(\\?"|\[)([0-9a-f]{8})\b)");
    static const QRegularExpression token_re(R"([0-9A-Za-z]{26,})");
    static const QRegularExpression xpub_re(R"(\b[tuvxyzTUVXYZ]p(?:ub|rv)[1-9A-HJ-NP-Za-km-z]{20,})");
    static const QRegularExpression bech32_re(R"(\b(?:bc|tb|bcrt|lq|tlq|ex|tex|el|ert)1[02-9ac-hj-np-z]{8,})");
    // log lines are truncated, so these values may be shorter than the HEX minimum
    static const QRegularExpression hex_field_re(R"((?:script|blinding_key|txhash|txid|blinder)\\?"\s*:\s*(?:String\(\\?"|")\K[0-9a-f]+)");
    static const QRegularExpression satoshi_re(R"(satoshi\\?"\s*:\s*(?:Number\()?\K-?\d+)");
    static const QRegularExpression satoshi_map_re(R"(satoshi\\?"\s*:\s*(?:Object\s*)?\{\K[^}]*)");
    static const QRegularExpression amount_re(R"(:\s*(?:Number\()?\K-?\d+)");
    static const QRegularExpression blob_re(R"((?:blob|hmac|encrypted_data)\\?"\s*:\s*(?:String\(\\?"|")\K[^\\"]+)");
    static const QRegularExpression short_hex_re(R"(\b[0-9a-f]{8}\b)");
    // nested values are escaped twice, and QDebug splits \x escapes with ""
    static const QRegularExpression name_re(R"(name(?:"\s*:\s*(?:String\()?"\K(?:\\.|[^\\"\r\n])+|\\"\s*:\s*(?:String\()?\\"\K(?:\\\\\\?.|\\?[^\\"\r\n]|"")+))");

    const auto home = QDir::homePath();
    const auto native_home = QDir::toNativeSeparators(home);
    const auto escaped_home = QString(native_home).replace('\\', QStringLiteral("\\\\"));

    QSet<QString> public_hex;
    QSet<QString> addresses;
    QSet<QString> fingerprints;
    QHash<QString, QString> placeholders;
    QHash<QString, int> counters;
    const auto placeholder = [&](const QString& kind, const QString& value) {
        auto& result = placeholders[value];
        if (result.isEmpty()) result = QStringLiteral("<%1_%2>").arg(kind).arg(++counters[kind]);
        return result;
    };

    // the log keeps growing while we read it
    const qint64 limit = in.size();
    while (in.pos() < limit && !in.atEnd()) {
        QString line = QString::fromUtf8(in.readLine());

        // network config and block hashes are public
        const bool is_network_config = line.contains(QLatin1String("create_session"));
        if (is_network_config) {
            for (auto it = hex_re.globalMatch(line); it.hasNext();) public_hex.insert(it.next().captured());
        }
        for (auto it = public_re.globalMatch(line); it.hasNext();) {
            const auto match = it.next();
            public_hex.insert(match.captured(1) + match.captured(2));
        }
        for (auto it = address_re.globalMatch(line); it.hasNext();) addresses.insert(it.next().captured(1));
        for (auto it = fingerprint_re.globalMatch(line); it.hasNext();) fingerprints.insert(it.next().captured(1));

        ReplaceMatches(line, token_re, [&](const QString& token) {
            return addresses.contains(token) ? placeholder("ADDR", token) : token;
        });
        ReplaceMatches(line, xpub_re, [&](const QString& xpub) { return placeholder("XPUB", xpub); });
        ReplaceMatches(line, bech32_re, [&](const QString& address) { return placeholder("ADDR", address); });
        ReplaceMatches(line, hex_re, [&](const QString& hex) {
            return public_hex.contains(hex) ? hex : placeholder("HEX", hex);
        });
        ReplaceMatches(line, hex_field_re, [&](const QString& hex) { return placeholder("HEX", hex); });
        ReplaceMatches(line, satoshi_re, [&](const QString& satoshi) { return placeholder("SAT", satoshi); });
        ReplaceMatches(line, satoshi_map_re, [&](QString amounts) {
            ReplaceMatches(amounts, amount_re, [&](const QString& satoshi) { return placeholder("SAT", satoshi); });
            return amounts;
        });
        ReplaceMatches(line, blob_re, [&](const QString& blob) { return placeholder("BLOB", blob); });
        if (!is_network_config) {
            ReplaceMatches(line, name_re, [&](const QString& name) { return placeholder("NAME", name); });
        }
        ReplaceMatches(line, short_hex_re, [&](const QString& hex) {
            return fingerprints.contains(hex) ? placeholder("FP", hex) : hex;
        });
        if (home != QDir::rootPath()) {
            line.replace(home, QStringLiteral("~"));
            line.replace(native_home, QStringLiteral("~"));
            line.replace(escaped_home, QStringLiteral("~"));
        }

        if (out.write(line.toUtf8()) < 0) return false;
    }
    return true;
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

bool IsSupportedPaymentUrl(const QString& url)
{
    const auto scheme = QUrl::fromUserInput(url).scheme();
    return scheme == "bitcoin" || scheme == "liquidnetwork" || scheme == "lightning";
}

QString GetPlatformName()
{
    const auto name = QSysInfo::productType();
    if (name == "macos") return name;
    if (name == "windows") return name;
    return "linux";
}

// Neutralizes spreadsheet formulas in untrusted text
QString CsvText(QString value)
{
    if (!value.isEmpty() && QStringLiteral("=+-@\t\r\n\uFF1D\uFF0B\uFF0D\uFF20").contains(value.front())) value.prepend("\t'");
    return value;
}

QString CsvLine(QStringList values)
{
    for (auto& value : values) {
        value = '"' + value.replace('"', "\"\"") + '"';
    }
    return values.join(',');
}

bool IsRunningAsFlatpak()
{
#ifdef Q_OS_LINUX
    return QFileInfo::exists(QStringLiteral("/.flatpak-info")) &&
           qEnvironmentVariableIsSet("FLATPAK_ID");
#else
    return false;
#endif
}

void ShowApplication()
{
#ifdef Q_OS_MACOS
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
#endif
}
