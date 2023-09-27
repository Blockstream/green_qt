import QtQuick
import QtQuick.Controls

AbstractButton {
    id: self
    padding: 16
    leftPadding: 16
    rightPadding: 16
    topPadding: 12
    bottomPadding: 12
    opacity: self.enabled ? 1 : 0.4
    background: Rectangle {
        color: 'transparent'
        border.width: 1
        border.color: '#FFF'
        radius: 8
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 12
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            opacity: self.visualFocus ? 1 : 0
        }
    }
    contentItem: Label {
        font.family: 'SF Compact Display'
        font.pixelSize: 16
        font.weight: 700
        horizontalAlignment: Text.AlignHCenter
        text: self.text
        verticalAlignment: Text.AlignVCenter
    }
}
