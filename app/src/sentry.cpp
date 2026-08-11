#include <QCoreApplication>
#include <QFile>

#include "config.h"
#include "util.h"

#ifdef ENABLE_SENTRY
#include <sentry.h>
#endif

void SentryInit()
{
    // Legacy crashpad database from releases before the sentry-native migration.
    if (!RemoveDataDir("crashpad")) {
        qWarning() << "Failed to remove legacy crashpad directory";
    }

#ifdef ENABLE_SENTRY
    sentry_options_t* sentry_options = sentry_options_new();
    sentry_options_set_dsn(sentry_options, "https://" SENTRY_KEY "@sentry.blockstream.io/" SENTRY_PROJECT);
    sentry_options_set_release(sentry_options, "green@" GREEN_VERSION);
    sentry_options_set_environment(sentry_options, GREEN_ENV);
    sentry_options_set_auto_session_tracking(sentry_options, 0);

    const QString sentry_database = GetDataDir("sentry");
    QString crashpad_handler = QCoreApplication::applicationDirPath()
#ifdef Q_OS_WIN
        + "/crashpad_handler.exe";
#else
        + "/crashpad_handler";
#endif

#ifdef Q_OS_LINUX
    // Inside a FUSE-mounted AppImage the squashfs mount is unmounted when the
    // process tree exits, pulling crashpad_handler and its dlopen'd libcurl.so.4
    // out from under the in-progress minidump upload (leaving the dump stuck in
    // "pending"). In a Flatpak built from the AppImage the sandbox filesystem is
    // read-only, causing the same symptom. Stage the handler and libcurl onto
    // persistent storage so the upload survives in both cases.
    if (qEnvironmentVariableIsSet("APPDIR") || IsRunningAsFlatpak()) {
        // Same directory name as the legacy crashpad database removed above.
        const QString staging = GetDataDir("crashpad");
        const QString app_dir = QCoreApplication::applicationDirPath();
        for (const auto& name : { QStringLiteral("crashpad_handler"), QStringLiteral("libcurl.so.4") }) {
            const QString dst = staging + "/" + name;
            QFile::remove(dst);
            if (QFile::copy(app_dir + "/" + name, dst)) {
                QFile::setPermissions(dst,
                    QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner |
                    QFileDevice::ReadGroup | QFileDevice::ExeGroup |
                    QFileDevice::ReadOther | QFileDevice::ExeOther);
            } else {
                qWarning() << "Failed to stage" << name << "for crashpad";
            }
        }
        // crashpad_handler dlopen()s libcurl.so.4 from its own dir ($ORIGIN).
        crashpad_handler = staging + "/crashpad_handler";
    }
#endif

#ifdef Q_OS_WIN
    sentry_options_set_database_pathw(sentry_options, reinterpret_cast<const wchar_t*>(sentry_database.utf16()));
    sentry_options_set_handler_pathw(sentry_options, reinterpret_cast<const wchar_t*>(crashpad_handler.utf16()));
#else
    sentry_options_set_database_path(sentry_options, sentry_database.toUtf8().constData());
    sentry_options_set_handler_path(sentry_options, crashpad_handler.toUtf8().constData());
#endif

    if (sentry_init(sentry_options) != 0) {
        qWarning() << "Failed to initialize sentry-native";
    }
#endif // ENABLE_SENTRY
}

void SentryClose()
{
#ifdef ENABLE_SENTRY
    sentry_close();
#endif
}
