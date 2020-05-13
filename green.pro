TARGET = Green

VERSION=0.0.1-beta1
VERSION_MAJOR = 0
VERSION_MINOR = 0
VERSION_PATCH = 1
VERSION_PRERELEASE = beta7
VERSION = $${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}

QMAKE_TARGET_COMPANY = Blockstream
QMAKE_TARGET_PRODUCT = Green
QMAKE_TARGET_DESCRIPTION = Blockstream Green
QMAKE_TARGET_COPYRIGHT = Blockstream Inc

DEFINES += "VERSION_MAJOR=$$VERSION_MAJOR"\
       "VERSION_MINOR=$$VERSION_MINOR"\
       "VERSION_PATCH=$$VERSION_PATCH" \
       "VERSION_PRERELEASE=\"$$VERSION_PRERELEASE\"" \
       "VERSION=\"$${VERSION_MAJOR}.$${VERSION_MINOR}.$${VERSION_PATCH}-$${VERSION_PRERELEASE}\""

QT += qml quick quickcontrols2 svg

CONFIG += c++11 qtquickcompiler

CONFIG += qzxing_qml qzxing_multimedia enable_decoder_qr_code enable_encoder_qr_code

include($$PWD/qzxing/src/QZXing-components.pri)

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS QZXING_QML

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += $$files(src/*.cpp)
HEADERS += $$files(src/*.h)
RESOURCES += qml/qml.qrc
RESOURCES += assets/assets.qrc
win32 {
    RESOURCES += src/win.qrc
} else {
    RESOURCES += src/linux.qrc
}

CONFIG += lrelease embed_translations

EXTRA_TRANSLATIONS = $$files($$PWD/i18n/*.ts)

INCLUDEPATH += $$PWD/gdk/include

macos {
    QMAKE_TARGET_BUNDLE_PREFIX = com.blockstream
    LIBS += -framework Foundation -framework Cocoa
}

GDK_BUILD_DIR = $$absolute_path($$(BUILDROOT)/gdk-$$(GDKBLDID)/src, $${PWD})


macos {
    ICON = Green.icns

    QMAKE_POST_LINK += \
        plutil -replace CFBundleDisplayName -string \"Blockstream Green\" $$OUT_PWD/$${TARGET}.app/Contents/Info.plist && \
        plutil -replace NSCameraUsageDescription -string \"We use the camera to scan QR codes\" $$OUT_PWD/$${TARGET}.app/Contents/Info.plist && \
        plutil -remove NOTE $$OUT_PWD/$${TARGET}.app/Contents/Info.plist || true

    static {
        LIBS += $$GDK_BUILD_DIR/build-clang/src/libgreenaddress_full.a
    } else {
        LIBS += -L$$GDK_BUILD_DIR/build-clang/src/ -lgreenaddress
    }
}

unix:!macos:!android {
    static {
        LIBS += $$GDK_BUILD_DIR/build-gcc/src/libgreenaddress_full.a
        SOURCES += src/glibc_compat.cpp
        LIBS += -Wl,--wrap=__divmoddi4 -Wl,--wrap=log2f
    } else {
        LIBS += -L$$GDK_BUILD_DIR/build-gcc/src -lgreenaddress
    }
}

win32:static {
    RC_ICONS = Green.ico

    LIBS += -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive
    LIBS += $$GDK_BUILD_DIR/build-windows-mingw-w64/src/libgreenaddress_full.a -lcrypt32 -lbcrypt -lws2_32 -liphlpapi -lssp -static-libgcc -static-libstdc++ -lwsock32
}

DEFINES += __PWD__=\\\"$$PWD\\\"

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    src/qtquickcontrols2.conf
