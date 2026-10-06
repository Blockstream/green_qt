#include <QApplication>
#include <QCameraDevice>
#include <QCommandLineParser>
#include <QDirIterator>
#include <QFileInfo>
#include <QFontDatabase>
#include <QIcon>
#include <QMediaDevices>
#include <QNetworkAccessManager>
#include <QNetworkDiskCache>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlNetworkAccessManagerFactory>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QScopeGuard>
#include <QSettings>
#include <QSGRendererInterface>
#include <QStyleHints>
#include <QTranslator>
#include <QUrl>

#include "analytics.h"
#include "application.h"
#include "assetmanager.h"
#include "clipboard.h"
#include "config.h"
#include "context.h"
#include "devicemanager.h"
#include "ga.h"
#include "green_settings.h"
#include "httpmanager.h"
#include "logging.h"
#include "networkmanager.h"
#include "sessionmanager.h"
#include "util.h"
#include "walletmanager.h"
#include "zxing.h"

#include <KDSingleApplication>

#ifdef _WIN32
#include <windows.h>
#endif

#include <cstdio>

#include <hidapi/hidapi.h>

void SentryInit();
void SentryClose();

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

int ui_handler(Application& app, int argc, char *argv[]) {
    KDSingleApplication kdsa("green_qt");

    WalletManager wallet_manager;
    SessionManager session_manager;
    ContextManager context_manager;

    if (g_args.positionalArguments().size() > 0) {
        wallet_manager.setOpenUrl(g_args.positionalArguments().first());
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

    ShowApplication();

#ifdef Q_OS_WIN
    QString path = QDir::toNativeSeparators(app.applicationFilePath());

    QSettings set("HKEY_CURRENT_USER\\Software\\Classes", QSettings::NativeFormat);
    const QStringList protocols = {"bitcoin", "liquidnetwork", "lightning"};
    for (const auto& protocol : protocols) {
        set.beginGroup(protocol);
        set.setValue("Default", QString("URL:%1").arg(protocol));
        set.setValue("DefaultIcon/Default", path);
        set.setValue("URL Protocol", "");
        set.setValue("shell/open/command/Default", QString("\"%1\"").arg(path) + " \"%1\"");
        set.endGroup();
    }
#endif

    app.connect(&kdsa, &KDSingleApplication::messageReceived, &app, [&app](const QByteArray &message ) {
        if (message == "raise") {
            app.raise();
        } else if (message.startsWith("open ")) {
            WalletManager::instance()->setOpenUrl(QString::fromUtf8(message.mid(5)));
            app.raise();
        }
    });

    // If app is launched with --ui flag directly, file open events are handled here
    QObject::connect(&app, &Application::fileOpenEventReceived, [&app, &wallet_manager](const QString& url) {
        qInfo() << "UI received FileOpen event directly:" << url;
        wallet_manager.setOpenUrl(url);
        app.raise();
    });

#if defined (Q_OS_LINUX)
    QApplication::setWindowIcon(QIcon(":/icons/production.png"));
#elif defined (Q_OS_MACOS)
    QApplication::setWindowIcon(QIcon(":/icons/mac-production.png"));
#elif defined (Q_OS_WINDOWS)
    QApplication::setWindowIcon(QIcon(":/icons/production.png"));
    if (AttachConsole(ATTACH_PARENT_PROCESS)) {
        freopen("CONOUT$", "w", stdout);
        freopen("CONOUT$", "w", stderr);
    }
#endif

    SentryInit();
    auto sentry_close = qScopeGuard([] { SentryClose(); });

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
    qInfo() << "Log file:" << qPrintable(GetLogFilename());
    qInfo() << "Initialize GDK";
    gdk::init(g_args);

    // Reset the locale that is used for number formatting, see:
    // https://doc.qt.io/qt-5/qcoreapplication.html#locale-settings
    setlocale(LC_NUMERIC, "C");

    QFontDatabase::addApplicationFont(":/fonts/Inter-Regular.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Inter-Medium.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Inter-SemiBold.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Inter-Bold.ttf");
    QFontDatabase::addApplicationFont(":/fonts/RobotoMono-Regular.ttf");

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
        const QString resource_path = it.next();
        if (!resource_path.endsWith(".qm")) continue;

        const QString base_name = QFileInfo(resource_path).baseName(); // e.g. green_en
        if (!base_name.startsWith("green_")) continue;

        const QString language_code = base_name.sliced(QString("green_").size());
        if (language_code.isEmpty()) continue;

        QLocale locale(language_code);
        const auto name = locale.nativeTerritoryName() + " - " + locale.nativeLanguageName();
        languages.insert(name, QVariantMap({{ "name", name }, { "language", language_code }}));
    }
    engine.rootContext()->setContextProperty("env", GREEN_ENV);
    engine.rootContext()->setContextProperty("languages", languages.values());
    engine.rootContext()->setContextProperty("data_location_path", g_data_location);
    engine.rootContext()->setContextProperty("data_location_url", QUrl::fromLocalFile(g_data_location));
    engine.rootContext()->setContextProperty("log_file_path", GetLogFilename());
    engine.rootContext()->setContextProperty("log_file_url", QUrl::fromLocalFile(GetLogFilename()));
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

    analytics.stop();
    http_manager.stop();
    context_manager.exit();
    session_manager.exit();

    return ret;
}
