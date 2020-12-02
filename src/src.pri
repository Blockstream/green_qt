SOURCES += \
    src/accountcontroller.cpp \
    src/account.cpp \
    src/asset.cpp \
    src/balance.cpp \
    src/clipboard.cpp \
    src/controller.cpp \
    src/createaccountcontroller.cpp \
    src/device.cpp \
    src/devicediscoveryagent.cpp \
    src/devicediscoveryagent_linux.cpp \
    src/devicediscoveryagent_macos.cpp \
    src/devicediscoveryagent_win.cpp \
    src/devicelistmodel.cpp \
    src/devicemanager.cpp \
    src/ga.cpp \
    src/json.cpp \
    src/main.cpp \
    src/network.cpp \
    src/networkmanager.cpp \
    src/renameaccountcontroller.cpp \
    src/resolver.cpp \
    src/restorecontroller.cpp \
    src/sendtransactioncontroller.cpp \
    src/signupcontroller.cpp \
    src/transaction.cpp \
    src/transactionlistmodel.cpp \
    src/twofactorcontroller.cpp \
    src/util.cpp \
    src/wallet.cpp \
    src/walletlistmodel.cpp \
    src/walletmanager.cpp \
    src/wally.cpp

HEADERS += \
    src/accountcontroller.h \
    src/account.h \
    src/asset.h \
    src/balance.h \
    src/clipboard.h \
    src/controller.h \
    src/createaccountcontroller.h \
    src/device.h \
    src/device_p.h \
    src/devicediscoveryagent.h \
    src/devicediscoveryagent_linux.h \
    src/devicediscoveryagent_macos.h \
    src/devicediscoveryagent_win.h \
    src/devicelistmodel.h \
    src/devicemanager.h \
    src/ga.h \
    src/json.h \
    src/network.h \
    src/networkmanager.h \
    src/renameaccountcontroller.h \
    src/resolver.h \
    src/restorecontroller.h \
    src/sendtransactioncontroller.h \
    src/signupcontroller.h \
    src/transaction.h \
    src/transactionlistmodel.h \
    src/twofactorcontroller.h \
    src/util.h \
    src/wallet.h \
    src/walletlistmodel.h \
    src/walletmanager.h \
    src/wally.h

include(controllers/controllers.pri)
include(handlers/handlers.pri)
include(resolvers/resolvers.pri)
