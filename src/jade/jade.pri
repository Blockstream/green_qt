INCLUDEPATH += $$PWD

QT += bluetooth serialport

HEADERS += \
    $$PWD/jadeapi.h \
    $$PWD/jadebleimpl.h \
    $$PWD/jadeconnection.h \
    $$PWD/jadedeviceserialportdiscoveryagent.h \
    $$PWD/jadelogincontroller.h \
    $$PWD/jadeserialimpl.h \
    $$PWD/jadedevice.h \
    $$PWD/deviceinfo.h \
    $$PWD/jadeupdatecontroller.h \
    $$PWD/serviceinfo.h

SOURCES += \
    $$PWD/jadeapi.cpp \
    $$PWD/jadebleimpl.cpp \
    $$PWD/jadeconnection.cpp \
    $$PWD/jadedeviceserialportdiscoveryagent.cpp \
    $$PWD/jadelogincontroller.cpp \
    $$PWD/jadeserialimpl.cpp \
    $$PWD/jadedevice.cpp \
    $$PWD/deviceinfo.cpp \
    $$PWD/jadeupdatecontroller.cpp \
    $$PWD/serviceinfo.cpp
