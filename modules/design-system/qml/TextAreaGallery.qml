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
        Layout.fillWidth: true
        colors: self.colors
        placeholderText: 'Enter a multiline support message'
        errorMessage: validation.checked ? 'Example caller-owned validation error with wrapping text.' : ''
        readOnly: readonly_toggle.checked
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
    }
}
