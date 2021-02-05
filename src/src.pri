INCLUDEPATH += $$PWD

SOURCES += \
    $$PWD/accountcontroller.cpp \
    $$PWD/account.cpp \
    $$PWD/asset.cpp \
    $$PWD/balance.cpp \
    $$PWD/clipboard.cpp \
    $$PWD/command.cpp \
    $$PWD/controller.cpp \
    $$PWD/createaccountcontroller.cpp \
    $$PWD/device.cpp \
    $$PWD/devicediscoveryagent.cpp \
    $$PWD/devicediscoveryagent_linux.cpp \
    $$PWD/devicediscoveryagent_macos.cpp \
    $$PWD/devicediscoveryagent_win.cpp \
    $$PWD/devicelistmodel.cpp \
    $$PWD/devicemanager.cpp \
    $$PWD/ga.cpp \
    $$PWD/json.cpp \
    $$PWD/main.cpp \
    $$PWD/network.cpp \
    $$PWD/networkmanager.cpp \
    $$PWD/renameaccountcontroller.cpp \
    $$PWD/resolver.cpp \
    $$PWD/restorecontroller.cpp \
    $$PWD/settings.cpp \
    $$PWD/signupcontroller.cpp \
    $$PWD/transaction.cpp \
    $$PWD/transactionlistmodel.cpp \
    $$PWD/twofactorcontroller.cpp \
    $$PWD/util.cpp \
    $$PWD/wallet.cpp \
    $$PWD/walletlistmodel.cpp \
    $$PWD/walletmanager.cpp \
    $$PWD/wally.cpp

HEADERS += \
    $$PWD/accountcontroller.h \
    $$PWD/account.h \
    $$PWD/asset.h \
    $$PWD/balance.h \
    $$PWD/clipboard.h \
    $$PWD/command.h \
    $$PWD/controller.h \
    $$PWD/createaccountcontroller.h \
    $$PWD/device.h \
    $$PWD/device_p.h \
    $$PWD/devicediscoveryagent.h \
    $$PWD/devicediscoveryagent_linux.h \
    $$PWD/devicediscoveryagent_macos.h \
    $$PWD/devicediscoveryagent_win.h \
    $$PWD/devicelistmodel.h \
    $$PWD/devicemanager.h \
    $$PWD/ga.h \
    $$PWD/json.h \
    $$PWD/network.h \
    $$PWD/networkmanager.h \
    $$PWD/renameaccountcontroller.h \
    $$PWD/resolver.h \
    $$PWD/restorecontroller.h \
    $$PWD/settings.h \
    $$PWD/signupcontroller.h \
    $$PWD/transaction.h \
    $$PWD/transactionlistmodel.h \
    $$PWD/twofactorcontroller.h \
    $$PWD/util.h \
    $$PWD/wallet.h \
    $$PWD/walletlistmodel.h \
    $$PWD/walletmanager.h \
    $$PWD/wally.h

include(core/core.pri)
include(controllers/controllers.pri)
include(handlers/handlers.pri)
include(resolvers/resolvers.pri)
include(ledger/ledger.pri)

win32 {
    RESOURCES += $$PWD/win.qrc
} else {
    RESOURCES += $$PWD/linux.qrc
}
