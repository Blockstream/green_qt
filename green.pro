TARGET = Green

VERSION_MAJOR = 0
VERSION_MINOR = 0
VERSION_PATCH = 3
VERSION_PRERELEASE =
VERSION = $${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}

QMAKE_TARGET_COMPANY = Blockstream Corporation Inc.
QMAKE_TARGET_PRODUCT = Blockstream Green
QMAKE_TARGET_DESCRIPTION = Blockstream Green
QMAKE_TARGET_COPYRIGHT = Copyright 2020 Blockstream Corporation Inc. All rights reserved.

DEFINES += "VERSION_MAJOR=$$VERSION_MAJOR"\
       "VERSION_MINOR=$$VERSION_MINOR"\
       "VERSION_PATCH=$$VERSION_PATCH" \
       "VERSION_PRERELEASE=\"$$VERSION_PRERELEASE\"" \
       "VERSION=\"$${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}\""

QML_IMPORT_NAME = Blockstream.Green
QML_IMPORT_MAJOR_VERSION = 0
QML_IMPORT_MINOR_VERSION = 1

QT += qml quick quickcontrols2 svg

CONFIG += c++11 metatypes qmltypes qtquickcompiler

CONFIG += qzxing_qml qzxing_multimedia enable_decoder_qr_code enable_encoder_qr_code

!defined(GDK_PATH, var): error(Run qmake with GDK_PATH set. See BUILD.md for more details.)
!defined(QZXING_PATH, var): error(Run qmake with QZXING_PATH set. See BUILD.md for more details.)

include($${QZXING_PATH}/src/QZXing-components.pri)

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    src/accountcontroller.cpp \
    src/account.cpp \
    src/asset.cpp \
    src/balance.cpp \
    src/clipboard.cpp \
    src/controller.cpp \
    src/createaccountcontroller.cpp \
    src/device.cpp \
    src/devicelistmodel.cpp \
    src/devicemanager.cpp \
    src/ga.cpp \
    src/handler.cpp \
    src/json.cpp \
    src/main.cpp \
    src/network.cpp \
    src/networkmanager.cpp \
    src/renameaccountcontroller.cpp \
    src/restorecontroller.cpp \
    src/sendtransactioncontroller.cpp \
    src/signupcontroller.cpp \
    src/transaction.cpp \
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
    src/devicelistmodel.h \
    src/devicemanager.h \
    src/ga.h \
    src/handler.h \
    src/json.h \
    src/network.h \
    src/networkmanager.h \
    src/renameaccountcontroller.h \
    src/restorecontroller.h \
    src/sendtransactioncontroller.h \
    src/signupcontroller.h \
    src/transaction.h \
    src/twofactorcontroller.h \
    src/util.h \
    src/wallet.h \
    src/walletlistmodel.h \
    src/walletmanager.h \
    src/wally.h

RESOURCES += assets/assets.qrc qml/qml.qrc assets/svg.qrc
win32 {
    RESOURCES += src/win.qrc
} else {
    RESOURCES += src/linux.qrc
}

CONFIG += lrelease embed_translations

EXTRA_TRANSLATIONS = $$files($$PWD/i18n/*.ts)

INCLUDEPATH += src/ $${GDK_PATH}

macos {
    QMAKE_TARGET_BUNDLE_PREFIX = com.blockstream
    LIBS += -framework Foundation -framework Cocoa
    ICON = Green.icns

    QMAKE_POST_LINK += \
        plutil -replace CFBundleDisplayName -string \"Blockstream Green\" $$OUT_PWD/$${TARGET}.app/Contents/Info.plist && \
        plutil -replace NSCameraUsageDescription -string \"We use the camera to scan QR codes\" $$OUT_PWD/$${TARGET}.app/Contents/Info.plist && \
        plutil -remove NOTE $$OUT_PWD/$${TARGET}.app/Contents/Info.plist || true

    static {
        LIBS += $${GDK_PATH}/libgreenaddress_full.a
    } else {
        LIBS += -L$${GDK_PATH} -lgreenaddress
    }
}

unix:!macos:!android {
    static {
        LIBS += $${GDK_PATH}/libgreenaddress_full.a
        SOURCES += src/glibc_compat.cpp
        LIBS += -Wl,--wrap=__divmoddi4 -Wl,--wrap=log2f
    } else {
        LIBS += -L$${GDK_PATH} -lgreenaddress
    }
    LIBS += -ludev
}

win32:static {
    # FIXME: the following script appends -lwinpthread at the end so that green .rsrc entries are used instead
    QMAKE_LINK=$${PWD}/link.sh
    RC_ICONS = Green.ico
    LIBS += $${GDK_PATH}/libgreenaddress_full.a /usr/x86_64-w64-mingw32/lib/libhid.a /usr/x86_64-w64-mingw32/lib/libsetupapi.a
}

DISTFILES += \
    src/qtquickcontrols2.conf
