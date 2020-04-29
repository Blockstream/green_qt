#include <QApplication>
#include <QFontDatabase>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QStyleHints>
#include <QTranslator>

#include "account.h"
#include "asset.h"
#include "balance.h"
#include "clipboard.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"
#include "walletmanager.h"
#include "wally.h"
#include "twofactorcontroller.h"
#include "settingscontroller.h"
#include "createaccountcontroller.h"
#include "sendtransactioncontroller.h"
#include "renameaccountcontroller.h"

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
        registerUncreatableType<Network>("Network");
        registerUncreatableType<Transaction>("Transaction");
        registerUncreatableType<TransactionAmount>("TransactionAmount");
        registerUncreatableType<Wallet>("Wallet");

        registerUncreatableType<Word>("Word");
        registerType<MnemonicEditorController>("MnemonicEditorController");

        registerType<CreateAccountController>("CreateAccountController");
        registerType<ReceiveAddress>("ReceiveAddress");
        registerType<RenameAccountController>("RenameAccountController");
        registerType<SendTransactionController>("SendTransactionController");
        registerType<BumpFeeController>("BumpFeeController");
        registerType<SettingsController>("SettingsController");
        registerType<TwoFactorController>("TwoFactorController");
        registerType<RequestTwoFactorResetController>("RequestTwoFactorResetController");
        registerType<CancelTwoFactorResetController>("CancelTwoFactorResetController");
        registerType<SetRecoveryEmailController>("SetRecoveryEmailController");

        registerSingletonInstance<Clipboard>("Clipboard");
        registerSingletonInstance<NetworkManager>("NetworkManager");
        registerSingletonInstance<WalletManager>("WalletManager");
    }

} // namespace Green

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName("Green");
    QCoreApplication::setOrganizationName("Blockstream");
    QCoreApplication::setOrganizationDomain("blockstream.com");
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
    QCoreApplication::setApplicationVersion(QT_STRINGIFY(VERSION));

    QApplication app(argc, argv);

    QApplication::setWindowIcon(QIcon(":/png/icon_1024x1024.png"));

    // Reset the locale that is used for number formatting, see:
    // https://doc.qt.io/qt-5/qcoreapplication.html#locale-settings
    setlocale(LC_NUMERIC, "C");

    const auto id = QFontDatabase::addApplicationFont(":/fonts/DINPro/DINPro-Regular.otf");
    Q_ASSERT(id >= 0);

    app.styleHints()->setTabFocusBehavior(Qt::TabFocusAllControls);

    const QLocale locale = QLocale::system();
    const QString language = locale.name().split('_').first();

    QTranslator language_translator;
    language_translator.load(QString(":/i18n/green_%1.qm").arg(language));

    QTranslator locale_translator;
    locale_translator.load(QString(":/i18n/green_%1.qm").arg(locale.name()));

    app.installTranslator(&language_translator);
    app.installTranslator(&locale_translator);

    QQuickStyle::setStyle("Material");

    QQmlApplicationEngine engine;
    engine.setBaseUrl(QUrl("qrc:/"));

    QZXing::registerQMLTypes();
    QZXing::registerQMLImageProvider(engine);

    Green::registerTypes();

    engine.load(QUrl(QStringLiteral("main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
