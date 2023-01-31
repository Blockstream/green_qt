import QtQuick
import QtQuick.Controls

ToolButton {
    id: self
    property var baseColor
    property var textColor: self.pressed ? "black" : "white"
    function _color(index) {
        if (baseColor) {
            return Qt.lighter(baseColor, 1 + 0.001 * index)
        } else {
            const prefix = self.highlighted ? 'g' : self.destructive ? 'r' : 'c'
            return constants[prefix + index]
        }
    }
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    topPadding: 0
    leftInset: 0
    rightInset: 0
    topInset: 0
    bottomInset: 0
    icon.height: 16
    icon.width: 16
    background: Rectangle {
        radius: Math.floor(Math.min(width, height) / 2)
        implicitWidth: 32
        implicitHeight: 32
        color: {
            if (!self.enabled) return _color(700)
            if (self.pressed) return 'white'
            if (self.activeFocus || self.hovered) return _color(600)
            return 'transparent' //_color(500)
        }
        border.width: self.activeFocus ? 1 : 0
        border.color: Qt.lighter(background.color)
    }
}
