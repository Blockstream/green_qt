import QtQuick
import QtQuick.Controls

AbstractButton {
    id: self
    font.family: 'SF Compact Display'
    font.pixelSize: 12
    font.weight: 400
    background: Item {
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            anchors.fill: self.parent
            anchors.margins: -4
            z: -1
            opacity: self.visualFocus ? 1 : 0
        }
    }
    contentItem: Label {
        color: '#00B45A'
        font: self.font
        text: self.text
    }
}
