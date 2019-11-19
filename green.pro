TARGET = Green

QT += qml quick quickcontrols2 svg widgets

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

SOURCES += \
    src/applicationengine.cpp \
    src/controllers/accountcontroller.cpp \
    src/controllers/controller.cpp \
    src/controllers/createaccountcontroller.cpp \
    src/controllers/renameaccountcontroller.cpp \
    src/controllers/sendtransactioncontroller.cpp \
    src/devices/device.cpp \
    src/devices/ledgernanoxdevice.cpp \
    src/account.cpp \
    src/devicemanager.cpp \
    src/ga.cpp \
    src/gui.cpp \
    src/main.cpp \
    src/network.cpp \
    src/transaction.cpp \
    src/twofactorcontroller.cpp \
    src/util.cpp \
    src/wallet.cpp \
    src/json.cpp \
    src/walletmanager.cpp \
    src/wally.cpp


HEADERS += \
    src/applicationengine.h \
    src/controllers/accountcontroller.h \
    src/controllers/controller.h \
    src/controllers/createaccountcontroller.h \
    src/controllers/renameaccountcontroller.h \
    src/controllers/sendtransactioncontroller.h \
    src/devices/device.h \
    src/devices/ledgernanoxdevice.h \
    src/account.h \
    src/devicemanager.h \
    src/ga.h \
    src/gui.h \
    src/network.h \
    src/transaction.h \
    src/twofactorcontroller.h \
    src/util.h \
    src/wallet.h \
    src/json.h \
    src/walletmanager.h \
    src/wally.h

RESOURCES += src/qml.qrc src/assets/assets.qrc

CONFIG += lrelease embed_translations

EXTRA_TRANSLATIONS = $$files($$PWD/src/i18n/*.ts)

INCLUDEPATH += $$PWD/gdk/include

macos {
    HEADERS += \
        src/devicemanagermacos.h
    SOURCES += \
        src/devicemanagermacos.cpp \
        src/mac.mm
    LIBS += -framework Foundation -framework Cocoa
}

GDK_BUILD_DIR = $$absolute_path($$(BUILDROOT)/gdk-$$(GDKBLDID)/src, $${PWD})

macos {
    static {
        LIBS += $$GDK_BUILD_DIR/build-clang/src/libgreenaddress_full.a
    } else {
        LIBS += -L$$GDK_BUILD_DIR/build-clang/src/ -lgreenaddress
    }
}

unix:!macos:!android:static {
    LIBS += $$GDK_BUILD_DIR/build-gcc/src/libgreenaddress_full.a
    SOURCES += src/glibc_compat.cpp
    LIBS += -Wl,--wrap=__divmoddi4 -Wl,--wrap=log2f
}

win32:static {
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
