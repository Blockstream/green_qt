INCLUDEPATH += $$PWD

SOURCES += \
    $$PWD/accountcontroller.cpp \
    $$PWD/account.cpp \
    $$PWD/accountlistmodel.cpp \
    $$PWD/activitymanager.cpp \
    $$PWD/address.cpp \
    $$PWD/addresslistmodel.cpp \
    $$PWD/addresslistmodelfilter.cpp \
    $$PWD/appupdatecontroller.cpp \
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
    $$PWD/entity.cpp \
    $$PWD/ga.cpp \
    $$PWD/httprequestactivity.cpp \
    $$PWD/json.cpp \
    $$PWD/main.cpp \
    $$PWD/navigation.cpp \
    $$PWD/network.cpp \
    $$PWD/networkmanager.cpp \
    $$PWD/newsfeedcontroller.cpp \
    $$PWD/renameaccountcontroller.cpp \
    $$PWD/resolver.cpp \
    $$PWD/restorecontroller.cpp \
    $$PWD/semver.cpp \
    $$PWD/session.cpp \
    $$PWD/settings.cpp \
    $$PWD/signupcontroller.cpp \
    $$PWD/output.cpp \
    $$PWD/outputlistmodel.cpp \
    $$PWD/outputlistmodelfilter.cpp \
    $$PWD/transaction.cpp \
    $$PWD/transactionlistmodel.cpp \
    $$PWD/twofactorcontroller.cpp \
    $$PWD/util.cpp \
    $$PWD/wallet.cpp \
    $$PWD/walletlistmodel.cpp \
    $$PWD/walletmanager.cpp \
    $$PWD/wally.cpp \
    $$PWD/watchonlylogincontroller.cpp

HEADERS += \
    $$PWD/accountcontroller.h \
    $$PWD/account.h \
    $$PWD/accountlistmodel.h \
    $$PWD/activitymanager.h \
    $$PWD/address.h \
    $$PWD/addresslistmodel.h \
    $$PWD/addresslistmodelfilter.h \
    $$PWD/appupdatecontroller.h \
    $$PWD/asset.h \
    $$PWD/balance.h \
    $$PWD/clipboard.h \
    $$PWD/command.h \
    $$PWD/connectable.h \
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
    $$PWD/entity.h \
    $$PWD/ga.h \
    $$PWD/httprequestactivity.h \
    $$PWD/json.h \
    $$PWD/navigation.h \
    $$PWD/network.h \
    $$PWD/networkmanager.h \
    $$PWD/newsfeedcontroller.h \
    $$PWD/renameaccountcontroller.h \
    $$PWD/resolver.h \
    $$PWD/restorecontroller.h \
    $$PWD/semver.h \
    $$PWD/session.h \
    $$PWD/settings.h \
    $$PWD/signupcontroller.h \
    $$PWD/output.h \
    $$PWD/outputlistmodel.h \
    $$PWD/outputlistmodelfilter.h \
    $$PWD/transaction.h \
    $$PWD/transactionlistmodel.h \
    $$PWD/twofactorcontroller.h \
    $$PWD/util.h \
    $$PWD/wallet.h \
    $$PWD/walletlistmodel.h \
    $$PWD/walletmanager.h \
    $$PWD/wally.h \
    $$PWD/watchonlylogincontroller.h

include(core/core.pri)
include(controllers/controllers.pri)
include(handlers/handlers.pri)
include(resolvers/resolvers.pri)
include(jade/jade.pri)
include(ledger/ledger.pri)

win32 {
    RESOURCES += $$PWD/win.qrc
} else {
    RESOURCES += $$PWD/linux.qrc
}
