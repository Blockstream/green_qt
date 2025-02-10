#include <QApplication>
#include <QCameraDevice>
#include <QCommandLineParser>
#include <QFontDatabase>
#include <QIcon>
#include <QMediaDevices>
#include <QNetworkAccessManager>
#include <QNetworkDiskCache>
#include <QQmlApplicationEngine>
#include <QQmlNetworkAccessManagerFactory>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QStyleHints>
#include <QtPlugin>
#include <QSGRendererInterface>
#include <QSettings>
#include <QTemporaryDir>
#include <QTranslator>
#include <QUrl>
#include <QWindow>

#include "config.h"
#include "application.h"
#include "analytics.h"
#include "asset.h"
#include "clipboard.h"
#include "devicemanager.h"
#include "ga.h"
#include "httpmanager.h"
#include "networkmanager.h"
#include "promo.h"
#include "sessionmanager.h"
#include "green_settings.h"
#include "util.h"
#include "walletmanager.h"

#include <KDSingleApplication>

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
#include <fcntl.h>
#include <io.h>
#include <windows.h>
#endif

#include <hidapi/hidapi.h>

extern QString g_data_location;
QCommandLineParser g_args;
QFile g_log_file;

#include <boost/log/core.hpp>
#include <boost/log/sinks/async_frontend.hpp>
#include <boost/log/sinks/basic_sink_backend.hpp>

static QString GraphicsAPIToString(QSGRendererInterface::GraphicsApi api) {
    switch (api) {
        case QSGRendererInterface::Software: return "Software";
        case QSGRendererInterface::OpenVG: return "OpenVG";
        case QSGRendererInterface::OpenGL: return "OpenGL";
        case QSGRendererInterface::Direct3D11: return "Direct3D11";
        case QSGRendererInterface::Direct3D12: return "Direct3D12";
        case QSGRendererInterface::Vulkan: return "Vulkan";
        case QSGRendererInterface::Metal: return "Metal";
        case QSGRendererInterface::Null: return "Null";
        default: return "Unknown";
    }
}

void gMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(context)

    static QHash<QtMsgType, QString> msgLevelHash({{QtDebugMsg, "debug"}, {QtInfoMsg, "info"}, {QtWarningMsg, "warning"}, {QtCriticalMsg, "critical"}, {QtFatalMsg, "fatal"}});
    QByteArray localMsg = msg.toLocal8Bit();
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzzzzz");
    QString logLevelName = msgLevelHash[type];

    QTextStream ts(&g_log_file);
    ts << QString("[%1] [app:%2] %3").arg(timestamp, logLevelName, msg) << Qt::endl;

    if (type == QtFatalMsg) abort();
}

class gdk_sink : public boost::log::sinks::basic_formatted_sink_backend<char> {
public:
    void consume(const boost::log::record_view&, const std::string& formatted_message)
    {
        QTextStream ts(&g_log_file);
        QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzzzzz");
        ts << QString("[%1] [gdk:info] %2").arg(timestamp, QString::fromStdString(formatted_message)) << Qt::endl;
    }
};

static QString g_gdk_debug_buffer;

void initLog()
{
    const QString log_file(GREEN_LOG_FILE);
    const QString version(GREEN_VERSION);

    g_log_file.setFileName(GetDataFile("logs", QString("%1.txt").arg(log_file.isEmpty() ? version : log_file)));

    if (QString{"Development"} != GREEN_ENV) {
        g_log_file.open(QIODevice::WriteOnly | QIODevice::Append);
        qInstallMessageHandler(gMessageHandler);

        using sink_t = boost::log::sinks::asynchronous_sink<gdk_sink>;
        auto sink = boost::make_shared<sink_t>(boost::make_shared<gdk_sink>());
        boost::log::core::get()->add_sink(sink);

        auto logger_thread = std::thread([] {
            int pipes[2];
            setvbuf(stdout, 0, _IOLBF, 0);
            setvbuf(stderr, 0, _IONBF, 0);
    #ifdef _WIN32
            _pipe(pipes, 1024, _O_NOINHERIT);
            _dup2(pipes[1], 1);
            _dup2(pipes[1], 2);
    #else
            pipe(pipes);
            dup2(pipes[1], 1);
            dup2(pipes[1], 2);
    #endif
            ssize_t read_size;
            char buffer[1024];
            while ((read_size = read(pipes[0], buffer, sizeof buffer - 1)) > 0) {
                g_gdk_debug_buffer.append(QByteArray(buffer, read_size));
                auto lines = g_gdk_debug_buffer.split('\n');
                QTextStream ts(&g_log_file);
                QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzzzzz");
                while (lines.size() > 1) {
                    ts << QString("[%1] [gdk:debug] %3").arg(timestamp, lines.takeFirst()) << Qt::endl;
                }
                g_gdk_debug_buffer = lines.first();
            }
        });
        logger_thread.detach();
    }
}

QString GetPlatformName()
{
    const auto name = QSysInfo::productType();
    if (name == "macos") return name;
    if (name == "windows") return name;
    return "linux";
}

class NetworkAccessManager : public QNetworkAccessManager {
public:
    explicit NetworkAccessManager(QObject *parent = nullptr) : QNetworkAccessManager(parent) {
        auto cache = new QNetworkDiskCache(this);
        cache->setCacheDirectory(GetDataDir("cache"));
        cache->setMaximumCacheSize(500 * 1024 * 1024);
        setCache(cache);
    }
};

class QmlNetworkAccessManagerFactory : public QQmlNetworkAccessManagerFactory {
public:
    QNetworkAccessManager *create(QObject *parent) override {
        return new NetworkAccessManager(parent);
    }
};

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName("Green");
    QCoreApplication::setOrganizationName("Blockstream");
    QCoreApplication::setOrganizationDomain("blockstream.com");
    QCoreApplication::setApplicationVersion(GREEN_VERSION);

    Application app(argc, argv);
    KDSingleApplication kdsa("green_qt");

    SessionManager session_manager;
    WalletManager wallet_manager;

    g_args.addHelpOption();
    g_args.addVersionOption();
    g_args.addOption(QCommandLineOption("datadir", "", "path"));
    g_args.addOption(QCommandLineOption("tempdatadir"));
    g_args.addOption(QCommandLineOption("printtoconsole"));
    g_args.addOption(QCommandLineOption("debug"));
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

    if (g_args.positionalArguments().size() > 0) {
        const auto uri = g_args.positionalArguments().first();
        const auto url = QUrl::fromUserInput(uri);
        const auto scheme = url.scheme();
        if (scheme == "http" || scheme == "bitcoin" || scheme == "liquidnetwork") {
            wallet_manager.setOpenUrl(uri);
        }
    }

    if (!kdsa.isPrimaryInstance()) {
        qInfo() << "Not primary instance";
        if (wallet_manager.hasOpenUrl()) {
            kdsa.sendMessage(QByteArray("open ") + wallet_manager.openUrl().toUtf8());
        } else {
            kdsa.sendMessage("raise");
        }
        return 0;
    }

#ifdef Q_OS_WIN
    QString path = QDir::toNativeSeparators(app.applicationFilePath());

    QSettings set("HKEY_CURRENT_USER\\Software\\Classes", QSettings::NativeFormat);
    set.beginGroup("bitcoin");
    set.setValue("Default", "URL:bitcoin");
    set.setValue("DefaultIcon/Default", path);
    set.setValue("URL Protocol", "");
    set.setValue("shell/open/command/Default", QString("\"%1\"").arg(path) + " \"%1\"");
    set.endGroup();
    set.beginGroup("liquidnetwork");
    set.setValue("Default", "URL:liquidnetwork");
    set.setValue("DefaultIcon/Default", path);
    set.setValue("URL Protocol", "");
    set.setValue("shell/open/command/Default", QString("\"%1\"").arg(path) + " \"%1\"");
    set.endGroup();
#endif

    app.connect(&kdsa, &KDSingleApplication::messageReceived, &app, [&app](const QByteArray &message ) {
        if (message == "raise") {
            app.raise();
        } else if (message.startsWith("open ")) {
            WalletManager::instance()->setOpenUrl(QString::fromUtf8(message.mid(5)));
            app.raise();
        }
    });

    if (g_args.isSet("tempdatadir")) {
        QTemporaryDir dir;
        Q_ASSERT(dir.isValid());
        dir.setAutoRemove(false);
        g_data_location = dir.path();
    } else if (g_args.isSet("datadir")) {
        QDir path(g_args.value("datadir"));
        g_data_location = path.absolutePath();
    } else {
        g_data_location = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    }

    // init log is called after setting the app name and version so that we have this information available for log location
    initLog();

#ifdef Q_OS_LINUX
    QCoreApplication::setApplicationName("Blockstream Green");
#endif

    if (g_args.isSet("printtoconsole")) {
#ifdef _WIN32
        if (AttachConsole(ATTACH_PARENT_PROCESS)) {
            freopen("CONOUT$", "w", stdout);
            freopen("CONOUT$", "w", stderr);
        }
#else
        Q_UNIMPLEMENTED();
#endif
    }

#ifndef Q_OS_MACOS
    QApplication::setWindowIcon(QIcon(":/icons/green.png"));
#endif

    auto video_inputs = QMediaDevices::videoInputs();

    qInfo() << qPrintable(QCoreApplication::organizationName()) << qPrintable(QCoreApplication::applicationName()) << qPrintable(QCoreApplication::applicationVersion());
    qInfo() << "Environment:" << GREEN_ENV;
    qInfo() << "System Information:";
    qInfo() << "  Build ABI:" << qPrintable(QSysInfo::buildAbi());
    qInfo() << "  Build CPU Architecture:" << qPrintable(QSysInfo::buildCpuArchitecture());
    qInfo() << "  Current CPU Architecture:" << qPrintable(QSysInfo::currentCpuArchitecture());
    qInfo() << "  Hardware Model:" << qPrintable(GetHardwareModel());
    qInfo() << "  Kernel Type:" << qPrintable(QSysInfo::kernelType());
    qInfo() << "  Kernel Version:" << qPrintable(QSysInfo::kernelVersion());
    qInfo() << "  Product:" << qPrintable(QSysInfo::prettyProductName());
    qInfo() << "  Product Type:" << qPrintable(QSysInfo::productType());
    qInfo() << "  Product Version:" << qPrintable(QSysInfo::productVersion());
    qInfo() << "  Video inputs:" << video_inputs.size();
    for (const auto video_input : video_inputs) {
        qInfo() << "    " << video_input.description() << (video_input.isDefault() ? "(default)" : "");
    }
    qInfo() << "Data directory:" << qPrintable(g_data_location);
    qInfo() << "Log file:" << qPrintable(g_log_file.fileName());
    qInfo() << "Initialize GDK";
    gdk::init(g_args);

    // Reset the locale that is used for number formatting, see:
    // https://doc.qt.io/qt-5/qcoreapplication.html#locale-settings
    setlocale(LC_NUMERIC, "C");

    QFontDatabase::addApplicationFont(":/fonts/inter_bold.ttf");
    QFontDatabase::addApplicationFont(":/fonts/inter_extra_light.ttf");
    QFontDatabase::addApplicationFont(":/fonts/inter_regular.ttf");
    QFontDatabase::addApplicationFont(":/fonts/inter_thin.ttf");
    QFontDatabase::addApplicationFont(":/fonts/monospace_bold.ttf");
    QFontDatabase::addApplicationFont(":/fonts/monospace_regular.ttf");

    app.styleHints()->setTabFocusBehavior(Qt::TabFocusAllControls);

    const QLocale locale = QLocale::system();
    const QString language = locale.name().split('_').first();

    qInfo() << "Load transalations";
    qInfo() << "  Language:" << qPrintable(language);
    qInfo() << "  Locale:" << qPrintable(locale.name());
    QTranslator english_translator;
    if (english_translator.load(":/i18n/green_en.qm")) {
        app.installTranslator(&english_translator);
    } else {
        qInfo() << "Failed to load en translations";
    }

    QTranslator language_translator;
    if (language_translator.load(QString(":/i18n/green_%1.qm").arg(language))) {
        app.installTranslator(&language_translator);
    } else {
        qInfo() << "Failed to load language translations";
    }

    QTranslator locale_translator;
    if (locale_translator.load(QString(":/i18n/green_%1.qm").arg(locale.name()))) {
        app.installTranslator(&locale_translator);
    } else {
        qInfo() << "Failed to load locale translations";
    }

    QQuickStyle::setStyle("Material");

    HttpManager http_manager;
    Analytics analytics;
    AssetManager asset_manager;
    PromoManager promo_manager;

    qInfo() << "Register singletons";
    qmlRegisterSingletonInstance<Clipboard>("Blockstream.Green.Core", 0, 1, "Clipboard", Clipboard::instance());
    qmlRegisterSingletonInstance<DeviceManager>("Blockstream.Green.Core", 0, 1, "DeviceManager", DeviceManager::instance());
    qmlRegisterSingletonInstance<HttpManager>("Blockstream.Green.Core", 0, 1, "HttpManager", HttpManager::instance());
    qmlRegisterSingletonInstance<NetworkManager>("Blockstream.Green.Core", 0, 1, "NetworkManager", NetworkManager::instance());
    qmlRegisterSingletonInstance<Settings>("Blockstream.Green.Core", 0, 1, "Settings", Settings::instance());
    qmlRegisterSingletonInstance<SessionManager>("Blockstream.Green.Core", 0, 1, "SessionManager", SessionManager::instance());
    qmlRegisterSingletonInstance<WalletManager>("Blockstream.Green.Core", 0, 1, "WalletManager", WalletManager::instance());
    qmlRegisterSingletonInstance<Analytics>("Blockstream.Green.Core", 0, 1, "Analytics", Analytics::instance());
    qmlRegisterSingletonInstance<AssetManager>("Blockstream.Green.Core", 0, 1, "AssetManager", AssetManager::instance());
    qmlRegisterSingletonInstance<PromoManager>("Blockstream.Green.Core", 0, 1, "PromoManager", PromoManager::instance());

    if (g_args.isSet("testnet")) {
        const auto value = g_args.value("testnet");
        Settings::instance()->setEnableTestnet(value.isEmpty() || value == "true" || value == "1");
    }
    if (g_args.isSet("analytics")) {
        Settings::instance()->setAnalytics(g_args.value("analytics"));
    }
    if (g_args.isSet("tor")) {
        Settings::instance()->setUseTor(g_args.value("tor") == "enabled");
    }
    if (g_args.isSet("proxy")) {
        const auto proxy = g_args.value("proxy").split(':');
        if (proxy.length() == 2) {
            Settings::instance()->setUseProxy(true);
            Settings::instance()->setProxyHost(proxy[0]);
            Settings::instance()->setProxyPort(proxy[1].toInt());
        }
    }

    qInfo() << "Load wallets";
    wallet_manager.loadWallets();

    qInfo() << "Setup QML root context";
    QQmlApplicationEngine engine;
    engine.setNetworkAccessManagerFactory(new QmlNetworkAccessManagerFactory);
    engine.setBaseUrl(QUrl("qrc:/Blockstream/Green/qml/"));

    QDirIterator it(":/i18n", QDirIterator::Subdirectories);
    QMap<QString, QVariant> languages;
    while (it.hasNext()) {
        const auto language = it.next().mid(13).chopped(3);
        QLocale locale(language);
        const auto name = locale.nativeTerritoryName() + " - " + locale.nativeLanguageName();
        languages.insert(name, QVariantMap({{ "name", name }, { "language", language }}));
    }
    engine.rootContext()->setContextProperty("env", GREEN_ENV);
    engine.rootContext()->setContextProperty("languages", languages.values());
    engine.rootContext()->setContextProperty("data_location_path", g_data_location);
    engine.rootContext()->setContextProperty("data_location_url", QUrl::fromLocalFile(g_data_location));
    engine.rootContext()->setContextProperty("log_file_path", g_log_file.fileName());
    engine.rootContext()->setContextProperty("log_file_url", QUrl::fromLocalFile(g_log_file.fileName()));
    engine.rootContext()->setContextProperty("platform", GetPlatformName());

    if (Settings::instance()->language().isEmpty()) {
        Settings::instance()->setLanguage(language);
    }

    QTranslator preferred_translator;
    if (preferred_translator.load(QString(":/i18n/green_%1.qm").arg(Settings::instance()->language()))) {
        app.installTranslator(&preferred_translator);
    }

    QObject::connect(Settings::instance(), &Settings::languageChanged, [&] {
        app.removeTranslator(&preferred_translator);
        const auto filename = QString(":/i18n/green_%1.qm").arg(Settings::instance()->language());
        if (preferred_translator.load(filename)) {
            app.installTranslator(&preferred_translator);
            engine.retranslate();
        }
    });

    engine.addImageProvider("zxing", new ZXingImageProvider);

    qInfo() << "Load GUI";
    engine.load(QUrl(QStringLiteral("main.qml")));
    if (engine.rootObjects().isEmpty()) {
        qInfo() << "Failed to load GUI";
        return -1;
    }

    auto window = qobject_cast<QQuickWindow*>(engine.rootObjects().first());
    if (!window) {
        qDebug() << "Failed to retrieve window";
        return -1;
    }

    qDebug() << "Window:";
    qDebug() << "  Graphics API: " << qPrintable(GraphicsAPIToString(window->rendererInterface()->graphicsApi()));

    qInfo() << "Start analytics";
    analytics.start();

    int ret = hid_init();
    if (ret != 0) return ret;
    qInfo() << "Enter event loop";
    ret = app.exec();
    qDebug() << "Event loop quit";
    hid_exit();
    return ret;
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
