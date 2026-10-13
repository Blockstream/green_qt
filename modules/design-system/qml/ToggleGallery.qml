import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    readonly property var settings: ['Notifications', 'Hide amounts', 'Remember device']
    readonly property var wrapModes: [
        { name: 'No wrap', value: Text.NoWrap },
        { name: 'Wrap', value: Text.Wrap },
        { name: 'Wrap anywhere', value: Text.WrapAnywhere }
    ]
    readonly property var elideModes: [
        { name: 'No elide', value: Text.ElideNone },
        { name: 'Elide right', value: Text.ElideRight },
        { name: 'Elide middle', value: Text.ElideMiddle },
        { name: 'Elide left', value: Text.ElideLeft }
    ]

    id: self
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            text: 'UiToggle'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'Hover a toggle, or use Tab and Space to inspect keyboard focus and activation. Edit the label text and wrap/elide modes to test long labels.'
            typography: Theme.typography.bodyS
            color: self.colors.textSubtle
            wrapMode: Text.Wrap
        }
    }
    GalleryCard {
        contentItem: ColumnLayout {
            spacing: 8
            UiLabel {
                text: 'Playground'
                typography: Theme.typography.labelLSemibold
                color: self.colors.textPrimary
            }
            UiTextField {
                id: label_text
                Layout.fillWidth: true
                size: UiTextField.Medium
                colors: self.colors
                placeholderText: 'Custom label for every toggle (try a long sentence)'
                Accessible.name: 'Toggle label text'
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                ComboBox {
                    id: wrap_selector
                    Layout.fillWidth: true
                    model: self.wrapModes
                    textRole: 'name'
                    Accessible.name: 'Wrap mode'
                }
                ComboBox {
                    id: elide_selector
                    Layout.fillWidth: true
                    model: self.elideModes
                    textRole: 'name'
                    Accessible.name: 'Elide mode'
                }
            }
            UiCheckbox {
                id: playground_disabled
                colors: self.colors
                text: 'Disabled'
            }
            Repeater {
                model: self.settings
                UiToggle {
                    required property string modelData

                    id: setting
                    Layout.fillWidth: true
                    Layout.maximumWidth: 360
                    colors: self.colors
                    text: label_text.text.length > 0 ? label_text.text : setting.modelData
                    wrapMode: self.wrapModes[wrap_selector.currentIndex]?.value ?? Text.NoWrap
                    elide: self.elideModes[elide_selector.currentIndex]?.value ?? Text.ElideNone
                    disabled: playground_disabled.checked
                }
            }
        }
    }

    component GalleryCard: Pane {
        Layout.fillWidth: true
        padding: 12
        background: Rectangle {
            color: self.colors.surfaceBase
            border.color: self.colors.borderSubtle
            radius: 6
        }
    }
}
