find_package(Qt6 6.11 CONFIG REQUIRED NO_MODULE COMPONENTS
    Concurrent
    Quick
    QuickControls2
    Widgets
    QuickWidgets
    Xml
    Core5Compat
    Bluetooth
    SerialPort
    LinguistTools
    Multimedia
    WebEngineQuick
)

find_package(Countly REQUIRED)
find_package(hidapi REQUIRED)
find_package(KDSingleApplication-qt6 CONFIG REQUIRED NO_MODULE)
find_package(libgpgme)
find_package(libserialport REQUIRED)
find_package(ZXing REQUIRED)
find_package(leveldb REQUIRED)

if (WIN32 AND NOT QT_FEATURE_static)
else()
    find_package(gdk CONFIG REQUIRED COMPONENTS green_gdk_full)
endif()

