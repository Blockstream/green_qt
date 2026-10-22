import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ScrollBar {
    property Colors colors: Theme.colors
    id: self
    padding: 2
    minimumSize: 0.05
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    Keys.onPressed: event => {
        if (!self.interactive) return
        const increaseKey = self.horizontal ? Qt.Key_Right : Qt.Key_Down
        const decreaseKey = self.horizontal ? Qt.Key_Left : Qt.Key_Up
        if (event.key === increaseKey) {
            self.increase()
            event.accepted = true
        } else if (event.key === decreaseKey) {
            self.decrease()
            event.accepted = true
        }
    }
    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: 3
        color: {
            if (!self.enabled) return self.colors.iconDisabled
            if (self.pressed) return self.colors.actionPressed
            if (self.hovered) return self.colors.iconBase
            return self.colors.iconSubtle
        }
        opacity: self.policy === Basic.ScrollBar.AlwaysOn || self.active || self.hovered || self.visualFocus ? 1 : 0
    }
    background: Rectangle {
        color: 'transparent'
        border.color: self.colors.borderFocus
        border.width: self.visualFocus ? 2 : 0
        radius: 5
    }
}
