import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.AbstractButton {
    property Colors colors: Theme.colors
    property bool disabled: false

    id: self
    padding: 24
    enabled: !self.disabled
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: self.text
    background: Rectangle {
        color: {
            if (self.down) return self.colors.surfaceSunken
            if (self.hovered && self.enabled) return self.colors.surfaceHover
            return self.colors.surfaceBase
        }
        border.color: self.visualFocus ? self.colors.borderFocus : self.colors.borderSubtle
        border.width: self.visualFocus ? 2 : 1
        radius: 8
    }
}
