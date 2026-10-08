qt_add_library(blockstream_controls STATIC)
set_target_properties(blockstream_controls PROPERTIES AUTOMOC ON)

qt_add_qml_module(blockstream_controls
    URI Blockstream.Controls
    VERSION 1.0
    DEPENDENCIES QtQuick QtQuick.Controls QtQuick.Controls.Basic QtQuick.Layouts QtQuick.Effects Blockstream.Theme
    QML_FILES
        UiButton.qml
        UiIcon.qml
        UiIconButton.qml
        UiLabel.qml
        UiRadio.qml
        UiSpinner.qml
        UiTextField.qml
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Blockstream/Controls"
)

target_link_libraries(blockstream_controls PUBLIC blockstream_themeplugin)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
