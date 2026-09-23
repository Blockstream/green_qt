#include <QtPlugin>
#include <QtWebEngineQuick>

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QEventLoop>
#include <QFile>
#include <QProcess>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QTextStream>

#include "application.h"
#include "config.h"
#include "logging.h"
#include "util.h"
#include "watchdog.h"

#if defined(QT_QPA_PLATFORM_WAYLAND)
Q_IMPORT_PLUGIN(QFFmpegMediaPlugin)
Q_IMPORT_PLUGIN(QWaylandIntegrationPlugin)
Q_IMPORT_PLUGIN(QWaylandBrcmEglPlatformIntegrationPlugin)
Q_IMPORT_PLUGIN(QWaylandEglPlatformIntegrationPlugin)
Q_IMPORT_PLUGIN(QWaylandXCompositeEglPlatformIntegrationPlugin)
Q_IMPORT_PLUGIN(QWaylandXCompositeGlxPlatformIntegrationPlugin)
#endif

#if defined(QT_QPA_PLATFORM_MINIMAL)
Q_IMPORT_PLUGIN(QMinimalIntegrationPlugin);
#endif
#if defined(QT_QPA_PLATFORM_XCB)
Q_IMPORT_PLUGIN(QFFmpegMediaPlugin);
Q_IMPORT_PLUGIN(QXcbIntegrationPlugin);
#elif defined(QT_QPA_PLATFORM_WINDOWS)
Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin);
#elif defined(QT_QPA_PLATFORM_COCOA)
Q_IMPORT_PLUGIN(QCocoaIntegrationPlugin);
#endif

#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif

extern QString g_data_location;
QCommandLineParser g_args;

int watchdog_handler(Application& app);
int ui_handler(Application& app, int argc, char *argv[]);

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName("Green");
    QCoreApplication::setOrganizationName("Blockstream");
    QCoreApplication::setOrganizationDomain("blockstream.com");
    QCoreApplication::setApplicationVersion(GREEN_VERSION);
    QApplication::setDesktopFileName("blockstream");

    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QtWebEngineQuick::initialize();

    Application app(argc, argv);

    g_args.addHelpOption();
    g_args.addVersionOption();
    g_args.addOption(QCommandLineOption("datadir", "", "path"));
    g_args.addOption(QCommandLineOption("tempdatadir"));
    g_args.addOption(QCommandLineOption("debug"));
    g_args.addOption(QCommandLineOption("ui"));
    g_args.addOption(QCommandLineOption("tor", "Configure Tor.", "enabled|disabled", ""));
    g_args.addOption(QCommandLineOption("proxy", "Configure Proxy.", "host:port", ""));
    g_args.addOption(QCommandLineOption("analytics", "Configure analytics.", "enabled|disabled", ""));
    g_args.addOption(QCommandLineOption("channel", "", "name", "latest"));
    g_args.addOption(QCommandLineOption("testnet"));
    g_args.addOption(QCommandLineOption("debugjade"));
    g_args.addOption(QCommandLineOption("jade", "Configure Jade.", "enabled|disabled", "enabled"));
    g_args.addOption(QCommandLineOption("updatecheckperiod", "Update check Period.", "seconds", "3600"));
    const bool is_production = QStringLiteral("Production") == GREEN_ENV;
    if (!is_production) {
        g_args.addOption(QCommandLineOption("mock-send", "Sending a transaction appears to succeed in the GUI but the transaction is not broadcasted to the network"));
    }
    g_args.addPositionalArgument("uri", "BIP21 payment");
    g_args.process(app);

    if (g_args.isSet("datadir")) {
        QDir path(g_args.value("datadir"));
        g_data_location = path.absolutePath();
    } else if (g_args.isSet("tempdatadir")) {
        QTemporaryDir dir;
        Q_ASSERT(dir.isValid());
        dir.setAutoRemove(false);
        g_data_location = dir.path();
    } else {
        g_data_location = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    }

    qInstallMessageHandler(logMessageHandler);

    // Legacy crashpad database from releases before the sentry-native migration.
    // sentry-native uses GetDataDir("sentry") now. Must stay above the AppImage
    // crashpad_handler staging in ui_handler(), which reuses this directory name.
    if (!RemoveDataDir("crashpad")) {
        qWarning() << "Failed to remove legacy crashpad directory";
    }

    // only change app name after setting g_data_location
    QCoreApplication::setApplicationName("Blockstream");

    for (auto arg : app.arguments()) {
        if (arg.startsWith("--ui")) {
            return ui_handler(app, argc, argv);
        }
    }
    return watchdog_handler(app);
}

int watchdog_handler(Application& app)
{
    QStringList args = app.arguments().mid(1);
    for (int i = 0; i < args.length();) {
        if (args[i] == "--tempdatadir") {
            args.removeAt(i);
        } else if (args[i] == "--datadir") {
            args.removeAt(i);
            args.removeAt(i);
        } else {
            i ++;
        }
    }
    args.append({ "--ui", "--datadir", g_data_location });

    const auto start_ui = [&app](QStringList args, int attempts = 1) {
        for (int i = 0; i < attempts; i++) {
            QFile file(GetLogFilename());
            (void)file.open(QFile::WriteOnly | QFile::Append);
            file.write("---------");
            file.flush();
            QProcess process;
            QEventLoop loop;
            QObject::connect(&process, &QProcess::readyReadStandardOutput, &loop, [&] {
                const auto data = process.readAllStandardOutput();
                write(0, data.constData(), data.size());
                file.write(data);
                file.flush();
            });
            QObject::connect(&process, &QProcess::readyReadStandardError, &loop, [&] {
                const auto data = process.readAllStandardError();
                write(1, data.constData(), data.size());
                file.write(data);
                file.flush();
            });
            QObject::connect(&process, &QProcess::finished, &loop, &QEventLoop::quit);
            process.start(app.arguments().constFirst(), args);
            loop.exec();
            const auto exit_status = process.exitStatus();
            const auto exit_code = process.exitCode();
            QTextStream(&file) << Q_FUNC_INFO << ' ' << DescribeUiExit(exit_status, exit_code) << Qt::endl;
            // only bring the UI back when it crashed, not when it was terminated on purpose
            if (!ShouldRestartUi(exit_status, exit_code)) break;
        }
    };

    QObject::connect(&app, &Application::fileOpenEventReceived, [&](const QString& url) {
        // It will start new UI process which will handle the URL and then exit immediately,
        // so we don't need to worry about killing it
        start_ui(args + QStringList{ url });
    });

    start_ui(args, 5);

    return 0;
}

#ifdef Q_OS_WIN
#include <mutex>
#if defined(_GLIBCXX_HAS_GTHREADS) && defined(_GLIBCXX_USE_C99_STDINT_TR1)
namespace {
  inline std::unique_lock<std::mutex>*&
  __get_once_functor_lock_ptr()
  {
    static std::unique_lock<std::mutex>* __once_functor_lock_ptr = 0;
    return __once_functor_lock_ptr;
  }
}

namespace std _GLIBCXX_VISIBILITY(default) {
_GLIBCXX_BEGIN_NAMESPACE_VERSION

// Explicit instantiation due to -fno-implicit-instantiation.
  template class function<void()>;
  function<void()> __once_functor;

  mutex&
  __get_once_mutex()
  {
    static mutex once_mutex;
    return once_mutex;
  }

  // code linked against ABI 3.4.12 and later uses this
  void
  __set_once_functor_lock_ptr(unique_lock<mutex>* __ptr)
  {
    __get_once_functor_lock_ptr() = __ptr;
  }

  // unsafe - retained for compatibility with ABI 3.4.11
  unique_lock<mutex>&
  __get_once_functor_lock()
  {
    static unique_lock<mutex> once_functor_lock(__get_once_mutex(), defer_lock);
    return once_functor_lock;
  }

#if 0
  extern "C"
  {
    void __once_proxy()
    {
      function<void()> __once_call = std::move(__once_functor);
      if (unique_lock<mutex>* __lock = __get_once_functor_lock_ptr()) {
        // caller is using new ABI and provided lock ptr
        __get_once_functor_lock_ptr() = 0;
        __lock->unlock();
      } else {
        __get_once_functor_lock().unlock();  // global lock
      }
      __once_call();
    }
  }
#endif

_GLIBCXX_END_NAMESPACE_VERSION
} // namespace std

#endif // _GLIBCXX_HAS_GTHREADS && _GLIBCXX_USE_C99_STDINT_TR1
#endif
