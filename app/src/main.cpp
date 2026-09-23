#include <QtPlugin>
#include <QtWebEngineQuick>

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QStandardPaths>
#include <QTemporaryDir>

#include "application.h"
#include "config.h"
#include "logging.h"

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

    // only change app name after setting g_data_location
    QCoreApplication::setApplicationName("Blockstream");

    for (auto arg : app.arguments()) {
        if (arg.startsWith("--ui")) {
            return ui_handler(app, argc, argv);
        }
    }
    return watchdog_handler(app);
}

