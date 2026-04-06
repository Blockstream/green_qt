#include "logging.h"

#include <QDateTime>
#include <QString>

#include <cerrno>
#include <cstdio>
#include <regex>
#include <string>
#include <thread>

#ifndef _WIN32
#include <unistd.h>
#endif

namespace {

struct LogLevel {
    const char* color;
    const char* label;
};

namespace color {
    constexpr const char* reset = "\033[0m";
    constexpr const char* gray = "\033[0;37m";
    constexpr const char* green = "\033[1;32m";
    constexpr const char* yellow = "\033[1;33m";
    constexpr const char* red = "\033[1;31m";
    constexpr const char* magenta = "\033[1;35m";
} // namespace color

#if defined(QT_DEBUG)
static const char* ansi(const char* code) { return code; }
#else
static const char* ansi(const char*) { return ""; }
#endif

LogLevel levelFromQtType(QtMsgType type)
{
    switch (type) {
    case QtDebugMsg: return {color::gray, "DEBUG"};
    case QtInfoMsg: return {color::green, "INFO "};
    case QtWarningMsg: return {color::yellow, "WARN "};
    case QtCriticalMsg: return {color::red, "ERROR"};
    case QtFatalMsg: return {color::magenta, "FATAL"};
    default: return {color::reset, ""};
    }
}

QString currentTimestamp()
{
    return QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss.zzz"));
}
}

void logMessageHandler(QtMsgType type, const QMessageLogContext& context, const QString& msg)
{
    const char* raw_category = context.category ? context.category : "default";
    const QString category = (qstrcmp(raw_category, "default") == 0)
        ? QStringLiteral("app")
        : QString::fromLatin1(raw_category);

    const auto lvl = levelFromQtType(type);
    fprintf(
        stderr, "[%s] %s%s [%s] %s%s\n",
        qPrintable(currentTimestamp()),
        ansi(lvl.color), lvl.label,
        qPrintable(category), qPrintable(msg),
        ansi(color::reset)
    );

    if (type == QtFatalMsg) abort();
}
