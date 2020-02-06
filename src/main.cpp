#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QStyleHints>
#include <QTranslator>
#include <QWindow>

#include "account.h"
#include "applicationengine.h"
#include "asset.h"
#include "balance.h"
#include "devices/device.h"
#include "gui.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"
#include "walletmanager.h"
#include "wally.h"
#include "twofactorcontroller.h"
#include "settingscontroller.h"
#include "controllers/createaccountcontroller.h"
#include "controllers/sendtransactioncontroller.h"
#include "controllers/renameaccountcontroller.h"

#if defined(Q_OS_MAC)
#include "devicemanagermacos.h"
#endif

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

class Translator : public QTranslator
{
public:
    virtual QString translate(const char *context, const char *sourceText, const char *disambiguation, int n) const;
};

QString Translator::translate(const char *context, const char *sourceText, const char *disambiguation, int n) const
{
    Q_UNUSED(context);
    return QTranslator::translate("green", sourceText, disambiguation, n);
}

namespace Green {

    namespace {

        const char* uri = "Blockstream.Green";
        const int version_major = 0;
        const int version_minor = 1;

        template <typename T>
        void registerUncreatableType(const char* qml_name)
        {
            qmlRegisterUncreatableType<T>(uri, version_major, version_minor, qml_name, QLatin1String("Trying to create uncreatable: %1").arg(qml_name));
        }

        template <typename T>
        void registerType(const char* qml_name)
        {
            qmlRegisterType<T>(uri, version_major, version_minor, qml_name);
        }

        template <typename T>
        void registerType(const char* uri, const char* qml_name)
        {
            qmlRegisterType<T>(uri, version_major, version_minor, qml_name);
        }


        template<typename T>
        void registerSingletonInstance(const char* qml_name)
        {
            qmlRegisterSingletonInstance(uri, version_major, version_minor, qml_name, T::instance());
        }

    } // namespace

    void registerTypes()
    {
        registerUncreatableType<Account>("Account");
        registerUncreatableType<Asset>("Asset");
        registerUncreatableType<Balance>("Balance");
        registerUncreatableType<Controller>("Controller");
        registerUncreatableType<Device>("Device");
        registerUncreatableType<Network>("Network");
        registerUncreatableType<Transaction>("Transaction");
        registerUncreatableType<TransactionAmount>("TransactionAmount");
        registerUncreatableType<Wallet>("Wallet");

        registerType<CreateAccountController>("CreateAccountController");
        registerType<ReceiveAddress>("ReceiveAddress");
        registerType<RenameAccountController>("RenameAccountController");
        registerType<SendTransactionController>("SendTransactionController");
        registerType<SettingsController>("SettingsController");
        registerType<TwoFactorController>("TwoFactorController");
        registerType<WordValidator>("WordValidator");

        registerSingletonInstance<NetworkManager>("NetworkManager");
        registerSingletonInstance<WalletManager>("WalletManager");
        registerSingletonInstance<Wally>("Wally");
    #if defined(Q_OS_MAC)
        registerSingletonInstance<DeviceManagerMacos>("DeviceManager");
    #endif

        registerType<Action>("Blockstream.Green.Gui", "Action");
        registerType<Menu>("Blockstream.Green.Gui", "Menu");
        registerType<MenuBar>("Blockstream.Green.Gui", "MenuBar");
        registerType<Separator>("Blockstream.Green.Gui", "Separator");
    }

} // namespace Green

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName("Green");
    QCoreApplication::setOrganizationName("Blockstream");
    QCoreApplication::setOrganizationDomain("blockstream.com");
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    QApplication app(argc, argv);

    // Reset the locale that is used for number formatting, see:
    // https://doc.qt.io/qt-5/qcoreapplication.html#locale-settings
    setlocale(LC_NUMERIC, "C");

    app.styleHints()->setTabFocusBehavior(Qt::TabFocusAllControls);

    const QLocale locale = QLocale::system();
    const QString language = locale.name().split('_').first();

    Translator language_translator;
    language_translator.load(QString(":/i18n/green_%1.qm").arg(language));

    Translator locale_translator;
    locale_translator.load(QString(":/i18n/green_%1.qm").arg(locale.name()));

    app.installTranslator(&language_translator);
    app.installTranslator(&locale_translator);

    QQuickStyle::setStyle("Material");

    ApplicationEngine engine;

    QZXing::registerQMLTypes();
    QZXing::registerQMLImageProvider(engine);

    Green::registerTypes();

    QMainWindow main_window;
    engine.rootContext()->setContextProperty("main_window", &main_window);

    engine.load(QUrl(QStringLiteral("loader.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    QWindow* window = static_cast<QWindow*>(engine.rootObjects().first());

    main_window.setWindowTitle("Blockstream Green");
    main_window.setCentralWidget(QWidget::createWindowContainer(window));
    main_window.setMinimumSize(QSize(1024, 600));
    main_window.show();

#if defined(Q_OS_MAC) || defined(Q_OS_UNIX)
    // Workaround due to https://bugreports.qt.io/browse/QTBUG-34414
    QObject::connect(&app, &QGuiApplication::focusWindowChanged, [&](QWindow* focusWindow) {
        if (focusWindow == main_window.windowHandle()) {
            main_window.centralWidget()->activateWindow();
            window->requestActivate();
        }
    });
#endif

    return app.exec();
}
