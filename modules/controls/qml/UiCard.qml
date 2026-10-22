import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.Pane {
    property Colors colors: Theme.colors

    id: self
    padding: 24
    background: Rectangle {
        color: self.colors.surfaceBase
        border.color: self.colors.borderSubtle
        border.width: 1
        radius: 4
    }
}
