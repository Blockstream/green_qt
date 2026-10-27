import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors

    id: self
    spacing: 24
    UiLabel {
        text: 'UiTextArea'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    UiTextArea {
        id: message
        Layout.fillWidth: true
        colors: self.colors
        placeholderText: 'Enter a multiline support message'
        errorMessage: validation.checked ? 'Example caller-owned validation error with wrapping text.' : ''
        readOnly: readonly_toggle.checked
        clearable: clearable_toggle.checked
        actions: Row {
            visible: actions_toggle.checked
            spacing: 4
            UiIconButton {
                variant: UiButton.Neutral
                size: UiButton.Small
                colors: self.colors
                text: 'Insert sample text'
                iconName: Theme.icons.clipboard
                disabled: message.readOnly
                onClicked: message.insert(message.cursorPosition, 'Sample message')
            }
            UiIconButton {
                variant: UiButton.Neutral
                size: UiButton.Small
                colors: self.colors
                text: 'Insert sample QR result'
                iconName: Theme.icons.qrCode
                disabled: message.readOnly
                onClicked: message.insert(message.cursorPosition, 'Sample QR result')
            }
        }
    }
    RowLayout {
        spacing: 16
        UiCheckbox {
            id: validation
            text: 'Show validation'
            colors: self.colors
        }
        UiCheckbox {
            id: readonly_toggle
            text: 'Read only'
            colors: self.colors
        }
        UiCheckbox {
            id: actions_toggle
            text: 'Show actions'
            checked: true
            colors: self.colors
        }
        UiCheckbox {
            id: clearable_toggle
            text: 'Clearable'
            checked: true
            colors: self.colors
        }
    }
}
