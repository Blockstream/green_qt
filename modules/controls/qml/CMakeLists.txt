qt_add_library(blockstream_controls STATIC)
set_target_properties(blockstream_controls PROPERTIES AUTOMOC ON)

qt_add_qml_module(blockstream_controls
    URI Blockstream.Controls
    VERSION 1.0
    DEPENDENCIES QtQuick QtQuick.Controls QtQuick.Controls.Basic QtQuick.Controls.Material QtQuick.Templates QtQuick.Layouts QtQuick.Effects QtQuick.Shapes Blockstream.Theme
    QML_FILES
        PopupAccessibility.qml
        UiAlertBanner.qml
        UiButton.qml
        UiCard.qml
        UiCardButton.qml
        UiCheckbox.qml
        UiDialog.qml
        UiDivider.qml
        UiDrawer.qml
        UiIcon.qml
        UiIconButton.qml
        UiLabel.qml
        UiLink.qml
        UiMenu.qml
        UiMenuItem.qml
        UiMenuSeparator.qml
        UiPopup.qml
        UiPopupSurface.qml
        UiRadio.qml
        UiSpinner.qml
        UiTab.qml
        UiTabs.qml
        UiTextField.qml
        UiToggle.qml
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Blockstream/Controls"
)

target_link_libraries(blockstream_controls PUBLIC blockstream_themeplugin)
