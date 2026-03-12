qt_policy(SET QTP0004 NEW)

qt_add_qml_module(${APP_TARGET}
    URI Blockstream.Green
    VERSION 1.0
    NO_PLUGIN
    DEPENDENCIES QtQuick
    SOURCES src/networkmanager.cpp
    QML_FILES ${BLOCKSTREAM_QML_FILES}
    RESOURCE_PREFIX /
    #ENABLE_TYPE_COMPILER
    NO_CACHEGEN
    NO_LINT
)
