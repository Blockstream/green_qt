import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolTip {
    property Colors colors: Theme.colors
    id: self
    padding: 8
    font: Theme.typography.bodyS.font
    contentItem: UiLabel {
        text: self.text
        typography: Theme.typography.bodyS
        color: self.colors.textPrimary
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
    }
    background: Rectangle {
        color: self.colors.surfaceOverlay
        border.color: self.colors.borderSubtle
        radius: 8
    }
}
