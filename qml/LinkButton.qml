import QtQuick
import QtQuick.Controls

AbstractButton {
    id: self
    focusPolicy: Qt.StrongFocus
    font.pixelSize: 14
    font.weight: 400
    background: Item {
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            opacity: self.enabled && self.visualFocus ? 1 : 0
        }
    }
    contentItem: Label {
        color: Qt.lighter('#00B45A', self.enabled && self.hovered ? 1.2 : 1)
        font: self.font
        text: self.text
        opacity: self.enabled ? 1 : 0.6
    }
}
