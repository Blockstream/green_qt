qt_add_library(blockstream_designsystem STATIC)
set_target_properties(blockstream_designsystem PROPERTIES AUTOMOC ON)

qt_add_qml_module(blockstream_designsystem
    URI Blockstream.DesignSystem
    VERSION 1.0
    DEPENDENCIES QtQuick QtQuick.Controls QtQuick.Controls.Material QtQuick.Layouts Blockstream.Theme Blockstream.Controls
    QML_FILES
        AlertBannerGallery.qml
        ButtonGallery.qml
        CardsGallery.qml
        catalog.js
        CheckboxGallery.qml
        ComboBoxGallery.qml
        DesignSystemPage.qml
        DesignSystemSwatch.qml
        DividerGallery.qml
        IconButtonGallery.qml
        IconGallery.qml
        LinkGallery.qml
        OverlaysGallery.qml
        PopupsGallery.qml
        ProgressGallery.qml
        RadioGallery.qml
        ScrollingGallery.qml
        TabsGallery.qml
        TextAreaGallery.qml
        TextFieldGallery.qml
        ToggleGallery.qml
        ToolTipGallery.qml
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Blockstream/DesignSystem"
)

target_link_libraries(blockstream_designsystem PUBLIC blockstream_controlsplugin)
