import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    readonly property var checkStateNames: ['Unchecked', 'Indeterminate', 'Checked']
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
            text: 'UiCheckbox'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'Hover a checkbox, or use Tab and Space to inspect keyboard focus and activation. Edit the label text and wrap/elide modes to test long labels.'
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
                text: 'Remember this device'
                Accessible.name: 'Checkbox label text'
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
            Flow {
                Layout.fillWidth: true
                spacing: 16
                UiCheckbox {
                    id: playground_tristate
                    colors: self.colors
                    text: 'Tri-state'
                }
                UiCheckbox {
                    id: playground_disabled
                    colors: self.colors
                    text: 'Disabled'
                }
            }
            UiCheckbox {
                id: playground_option
                Layout.fillWidth: true
                colors: self.colors
                text: label_text.text
                wrapMode: self.wrapModes[wrap_selector.currentIndex]?.value ?? Text.NoWrap
                elide: self.elideModes[elide_selector.currentIndex]?.value ?? Text.ElideNone
                tristate: playground_tristate.checked
                disabled: playground_disabled.checked
            }
            UiLabel {
                text: `checkState: ${self.checkStateNames[playground_option.checkState] ?? ''}`
                typography: Theme.typography.bodyS
                color: self.colors.textSubtle
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
