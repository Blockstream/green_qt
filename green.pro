TARGET = Green

QMAKE_CXXFLAGS_RELEASE += -flto
QMAKE_LDFLAGS_RELEASE += -flto

QT += qml quick quickcontrols2 svg widgets

CONFIG += c++11 qtquickcompiler qzxing_qml qzxing_multimedia

include($$PWD/qzxing/src/QZXing.pri)

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
    src/controllers/accountcontroller.cpp \
    src/controllers/controller.cpp \
    src/controllers/createaccountcontroller.cpp \
    src/controllers/renameaccountcontroller.cpp \
    src/controllers/sendtransactioncontroller.cpp \
    src/devices/abstractdevice.cpp \
    src/devices/ledgernanoxdevice.cpp \
    src/account.cpp \
    src/devicemanager.cpp \
    src/ga.cpp \
    src/main.cpp \
    src/twofactorcontroller.cpp \
    src/wallet.cpp \
    src/json.cpp \
    src/walletmanager.cpp


HEADERS += \
    src/controllers/accountcontroller.h \
    src/controllers/controller.h \
    src/controllers/createaccountcontroller.h \
    src/controllers/renameaccountcontroller.h \
    src/controllers/sendtransactioncontroller.h \
    src/devices/abstractdevice.h \
    src/devices/ledgernanoxdevice.h \
    src/account.h \
    src/devicemanager.h \
    src/devicemanagermacos.h \
    src/ga.h \
    src/twofactorcontroller.h \
    src/wallet.h \
    src/json.h \
    src/walletmanager.h

RESOURCES += src/qml.qrc

INCLUDEPATH += $$PWD/gdk/include

macos {
    SOURCES += \
        src/devicemanagermacos.cpp \
        src/mac.mm
    LIBS += -framework Foundation -framework Cocoa
    LIBS += -L../gdk/build-clang/src/ -lgreenaddress
}

unix:!macos:!android {
    LIBS += $$(BUILDROOT)/gdk-$$(GDKVERSION)/src/build-gcc/src/libgreenaddress_full.a
}


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
