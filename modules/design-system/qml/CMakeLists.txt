qt_add_library(blockstream_designsystem STATIC)
set_target_properties(blockstream_designsystem PROPERTIES AUTOMOC ON)

qt_add_qml_module(blockstream_designsystem
    URI Blockstream.DesignSystem
    VERSION 1.0
    DEPENDENCIES QtQuick QtQuick.Controls QtQuick.Controls.Material QtQuick.Layouts Blockstream.Theme Blockstream.Controls
    QML_FILES
        ButtonGallery.qml
        IconGallery.qml
        IconButtonGallery.qml
        DesignSystemPage.qml
        DesignSystemSwatch.qml
        TextFieldGallery.qml
        RadioGallery.qml
        CheckboxGallery.qml
        ToggleGallery.qml
        DividerGallery.qml
        LinkGallery.qml
        TabsGallery.qml
        catalog.js
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Blockstream/DesignSystem"
)

target_link_libraries(blockstream_designsystem PUBLIC blockstream_controlsplugin)
