#include <QApplication>
#include <QCommandLineParser>
#include <QFontDatabase>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QStyleHints>
#include <QTranslator>
#include <QWindow>

#include "clipboard.h"
#include "devicemanager.h"
#include "networkmanager.h"
#include "settings.h"
#include "walletmanager.h"
#include "kdsingleapplication.h"

#include <QZXing.h>

#include <QtPlugin>
#if defined(QT_QPA_PLATFORM_MINIMAL)
Q_IMPORT_PLUGIN(QMinimalIntegrationPlugin);
#endif
#if defined(QT_QPA_PLATFORM_XCB)
Q_IMPORT_PLUGIN(QXcbIntegrationPlugin);
#elif defined(QT_QPA_PLATFORM_WINDOWS)
Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin);
#elif defined(QT_QPA_PLATFORM_COCOA)
Q_IMPORT_PLUGIN(QCocoaIntegrationPlugin);
#endif

#ifdef _WIN32
#include <windows.h>
#endif

#include <hidapi/hidapi.h>

extern QString g_data_location;

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName("Green");
    QCoreApplication::setOrganizationName("Blockstream");
    QCoreApplication::setOrganizationDomain("blockstream.com");
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
    QCoreApplication::setApplicationVersion(QT_STRINGIFY(VERSION));

    g_data_location = QStandardPaths::writableLocation(QStandardPaths::DataLocation);
#ifdef Q_OS_LINUX
    QCoreApplication::setApplicationName("Blockstream Green");
#endif

    QApplication app(argc, argv);
    KDSingleApplication kdsa;

    if (!kdsa.isPrimaryInstance()) {
        kdsa.sendMessage("raise");
        return 0;
    }

    #ifndef Q_OS_LINUX
    app.connect(&kdsa, &KDSingleApplication::messageReceived, &app, [&app](const QByteArray &message ) {
        if (message == "raise") {
            for (QWindow* w : app.allWindows()) {
                // windows: does not allow a window to be brought to front while the user has focus on another window
                // instead, Windows flashes the taskbar button of the window to notify the user

                // mac: if the primary window is minimized, it is restored. It is background, it is brough to foreground

                w->showNormal();
                w->requestActivate();
                w->raise();
            }
        }
    });
    #endif

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addOption(QCommandLineOption("printtoconsole"));
    parser.addOption(QCommandLineOption("debugfocus"));
    parser.addOption(QCommandLineOption("debugjade"));
    parser.process(app);

    if (parser.isSet("printtoconsole")) {
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

    // Reset the locale that is used for number formatting, see:
    // https://doc.qt.io/qt-5/qcoreapplication.html#locale-settings
    setlocale(LC_NUMERIC, "C");

    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-Medium.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-Light.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-Regular.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-MediumItalic.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-ThinItalic.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-BoldItalic.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-LightItalic.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-Italic.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-BlackItalic.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-Bold.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-Thin.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Roboto/Roboto-Black.ttf");

    app.styleHints()->setTabFocusBehavior(Qt::TabFocusAllControls);

    const QLocale locale = QLocale::system();
    const QString language = locale.name().split('_').first();

    QTranslator english_translator;
    english_translator.load(":/i18n/green_en.qm");

    QTranslator language_translator;
    language_translator.load(QString(":/i18n/green_%1.qm").arg(language));

    QTranslator locale_translator;
    locale_translator.load(QString(":/i18n/green_%1.qm").arg(locale.name()));

    app.installTranslator(&english_translator);
    app.installTranslator(&language_translator);
    app.installTranslator(&locale_translator);

    QQuickStyle::setStyle("Material");

    WalletManager wallet_manager;

    qmlRegisterSingletonInstance<Clipboard>("Blockstream.Green.Core", 0, 1, "Clipboard", Clipboard::instance());
    qmlRegisterSingletonInstance<DeviceManager>("Blockstream.Green.Core", 0, 1, "DeviceManager", DeviceManager::instance());
    qmlRegisterSingletonInstance<NetworkManager>("Blockstream.Green.Core", 0, 1, "NetworkManager", NetworkManager::instance());
    qmlRegisterSingletonInstance<Settings>("Blockstream.Green.Core", 0, 1, "Settings", Settings::instance());
    qmlRegisterSingletonInstance<WalletManager>("Blockstream.Green.Core", 0, 1, "WalletManager", WalletManager::instance());

    QQmlApplicationEngine engine;
    engine.setBaseUrl(QUrl("qrc:/"));

    QZXing::registerQMLTypes();
    QZXing::registerQMLImageProvider(engine);

    engine.load(QUrl(QStringLiteral("main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    int ret = hid_init();
    if (ret != 0) return ret;
    ret = app.exec();
    hid_exit();
    return ret;
}

#ifdef Q_OS_WIN
#include <mutex>
#if defined(_GLIBCXX_HAS_GTHREADS) && defined(_GLIBCXX_USE_C99_STDINT_TR1)
namespace
{
  inline std::unique_lock<std::mutex>*&
  __get_once_functor_lock_ptr()
  {
    static std::unique_lock<std::mutex>* __once_functor_lock_ptr = 0;
    return __once_functor_lock_ptr;
  }
}

namespace std _GLIBCXX_VISIBILITY(default)
{
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

  extern "C"
  {
    void __once_proxy()
    {
      function<void()> __once_call = std::move(__once_functor);
      if (unique_lock<mutex>* __lock = __get_once_functor_lock_ptr())
      {
        // caller is using new ABI and provided lock ptr
        __get_once_functor_lock_ptr() = 0;
        __lock->unlock();
      }
      else
        __get_once_functor_lock().unlock();  // global lock
      __once_call();
    }
  }

_GLIBCXX_END_NAMESPACE_VERSION
} // namespace std

#endif // _GLIBCXX_HAS_GTHREADS && _GLIBCXX_USE_C99_STDINT_TR1
#endif
