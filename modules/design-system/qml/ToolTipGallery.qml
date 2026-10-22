import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors

    id: self
    spacing: 24
    UiLabel {
        text: 'UiToolTip'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    UiButton {
        id: hint_button
        text: 'Hover for a tooltip'
        colors: self.colors
        UiToolTip {
            colors: self.colors
            visible: hint_button.hovered
            text: 'A themed hover hint'
            delay: 400
        }
    }
}
