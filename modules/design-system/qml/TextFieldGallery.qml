import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    readonly property var sizes: [
        { name: 'Large · 60px', value: UiTextField.Large },
        { name: 'Medium · 44px', value: UiTextField.Medium },
        { name: 'Small · 36px', value: UiTextField.Small }
    ]

    id: self
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            text: 'UiTextField'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'Configure the field below. Hover, click, or use Tab to inspect focus; Tab through the enabled field actions.'
            typography: Theme.typography.bodyS
            color: self.colors.textSubtle
            wrapMode: Text.Wrap
        }
    }
    Pane {
        Layout.fillWidth: true
        padding: 12
        background: Rectangle {
            color: self.colors.surfaceBase
            border.color: self.colors.borderSubtle
            radius: 6
        }
        contentItem: ColumnLayout {
            spacing: 12
            GridLayout {
                id: field_settings
                Layout.fillWidth: true
                columns: self.width >= 600 ? 2 : 1
                uniformCellWidths: true
                columnSpacing: 12
                rowSpacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    UiLabel {
                        text: 'Size'
                        typography: Theme.typography.bodyS
                        color: self.colors.textSubtle
                    }
                    ComboBox {
                        id: size_selector
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        model: self.sizes
                        textRole: 'name'
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    UiLabel {
                        text: 'Validator'
                        typography: Theme.typography.bodyS
                        color: self.colors.textSubtle
                    }
                    ComboBox {
                        id: validator_selector
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        model: ['None', 'Integer · 0–9999']
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.columnSpan: field_settings.columns
                    UiLabel {
                        text: 'Error message · leave empty for no error'
                        typography: Theme.typography.bodyS
                        color: self.colors.textSubtle
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    UiTextField {
                        id: error_input
                        colors: self.colors
                        size: UiTextField.Medium
                        placeholderText: 'Error message'
                    }
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 16
                UiCheckbox {
                    id: disabled_toggle
                    colors: self.colors
                    text: 'Disabled'
                }
                UiCheckbox {
                    id: readonly_toggle
                    colors: self.colors
                    text: 'Read-only'
                }
                UiCheckbox {
                    id: clearable_toggle
                    colors: self.colors
                    text: 'Clearable'
                    checked: true
                }
                UiCheckbox {
                    id: leading_icon_toggle
                    colors: self.colors
                    text: 'Leading icon'
                }
                UiCheckbox {
                    id: leading_action_toggle
                    colors: self.colors
                    text: 'Leading action · select all'
                }
                UiCheckbox {
                    id: trailing_action_toggle
                    colors: self.colors
                    text: 'Trailing action · copy'
                }
            }
            UiTextField {
                id: sample
                Accessible.id: 'gallery_text_field'
                iconName: leading_icon_toggle.checked ? Theme.icons.magnifyingGlass : ''
                leadingItem: leading_action_toggle.checked ? select_action : null
                trailingItem: trailing_action_toggle.checked ? copy_action : null
                UiIconButton {
                    id: select_action
                    visible: leading_action_toggle.checked
                    text: 'Select all'
                    iconName: Theme.icons.check
                    colors: self.colors
                    size: UiButton.Small
                    variant: UiButton.Neutral
                    Accessible.id: sample.Accessible.id + '_select_all'
                    onClicked: {
                        sample.forceActiveFocus()
                        sample.selectAll()
                    }
                }
                UiIconButton {
                    id: copy_action
                    visible: trailing_action_toggle.checked
                    text: 'Copy'
                    iconName: Theme.icons.copy
                    colors: self.colors
                    variant: UiButton.Neutral
                    size: UiButton.Small
                    Accessible.id: sample.Accessible.id + '_copy'
                    onClicked: Clipboard.copy(sample.text)
                }
                Layout.maximumWidth: 325
                colors: self.colors
                size: self.sizes[size_selector.currentIndex]?.value ?? UiTextField.Large
                placeholderText: 'Placeholder'
                errorMessage: error_input.text
                disabled: disabled_toggle.checked
                readOnly: readonly_toggle.checked
                clearable: clearable_toggle.checked
                validator: validator_selector.currentIndex === 1 ? integer_validator : null
                IntValidator {
                    id: integer_validator
                    bottom: 0
                    top: 9999
                }
            }
        }
    }
}
