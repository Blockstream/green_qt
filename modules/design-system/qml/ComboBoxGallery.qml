import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors

    id: self
    spacing: 24
    UiLabel {
        text: 'UiComboBox'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    UiComboBox {
        Layout.fillWidth: true
        colors: self.colors
        model: Array.from({ length: 30 }, (_, index) => 'Option ' + (index + 1))
    }
}
