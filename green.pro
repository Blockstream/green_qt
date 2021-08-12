TARGET = green

macos {
    TARGET = "Blockstream Green"
}

QMAKE_TARGET_COMPANY = Blockstream Corporation Inc.
QMAKE_TARGET_PRODUCT = $${TARGET}
QMAKE_TARGET_DESCRIPTION = $${TARGET}
QMAKE_TARGET_COPYRIGHT = Copyright 2021 Blockstream Corporation Inc. All rights reserved.


QML_IMPORT_NAME = Blockstream.Green
QML_IMPORT_MAJOR_VERSION = 0
QML_IMPORT_MINOR_VERSION = 1

QT += qml quick quickcontrols2 svg concurrent xml

CONFIG += c++17 metatypes qmltypes qtquickcompiler sdk_no_version_check

!defined(GDK_PATH, var): error(Run qmake with GDK_PATH set. See BUILD.md for more details.)
DEFINES += BUILD_ELEMENTS

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

include(release.pri)
include(qzxing.pri)
include(hidapi.pri)
include(assets/assets.pri)
include(qml/qml.pri)
include(src/src.pri)
include(sa/sa.pri)

CONFIG += lrelease embed_translations

EXTRA_TRANSLATIONS = $$files($$PWD/i18n/*.ts)

INCLUDEPATH += $${GDK_PATH}

macos {
    QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.13
    QMAKE_TARGET_BUNDLE_PREFIX = com.blockstream
    LIBS += -framework Foundation -framework Cocoa
    ICON = assets/icons/green.icns

    QMAKE_POST_LINK += \
        plutil -replace CFBundleName -string \"$${TARGET}\" \"$$OUT_PWD/$${TARGET}.app/Contents/Info.plist\" && \
        plutil -replace CFBundleDisplayName -string \"$${TARGET}\" \"$$OUT_PWD/$${TARGET}.app/Contents/Info.plist\" && \
        plutil -replace NSCameraUsageDescription -string \"We use the camera to scan QR codes\" \"$$OUT_PWD/$${TARGET}.app/Contents/Info.plist\"

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
    RC_ICONS = assets/icons/green.ico

    INCLUDEPATH += $${DEPS_PATH}/hidapi/include

    LIBS += $${GDK_PATH}/libgreenaddress_full.a
    LIBS += $${DEPS_PATH}/hidapi/lib/libhidapi.a
    LIBS += /usr/x86_64-w64-mingw32/lib/libhid.a /usr/x86_64-w64-mingw32/lib/libsetupapi.a
}

win32:shared {
    QMAKE_LINK=$${PWD}/link.bat

    INCLUDEPATH += $${DEPS_PATH}/hidapi/include

    LIBS += $${GDK_PATH}/libgreenaddress_full.a
    LIBS += $${DEPS_PATH}/hidapi/lib/libhidapi.a
}

DISTFILES += \
    src/qtquickcontrols2.conf
