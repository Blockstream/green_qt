qt_add_library(blockstream_theme STATIC)
set_target_properties(blockstream_theme PROPERTIES AUTOMOC ON)

set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(blockstream_theme
    URI Blockstream.Theme
    VERSION 1.0
    DEPENDENCIES QtQuick
    QML_FILES
        Theme.qml
        Colors.qml
        Icons.qml
        LightColors.qml
        DarkColors.qml
        Typography.qml
        TypographyStyle.qml
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Blockstream/Theme"
)

add_subdirectory(icons)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
