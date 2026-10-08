qt_add_library(blockstream_controls STATIC)
set_target_properties(blockstream_controls PROPERTIES AUTOMOC ON)

qt_add_qml_module(blockstream_controls
    URI Blockstream.Controls
    VERSION 1.0
    DEPENDENCIES QtQuick Blockstream.Theme
    QML_FILES
        UiLabel.qml
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Blockstream/Controls"
)

target_link_libraries(blockstream_controls PUBLIC blockstream_themeplugin)
