import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: self
    focusPolicy: Qt.StrongFocus
    padding: 16
    leftPadding: 16
    rightPadding: 16
    topPadding: 12
    bottomPadding: 12
    opacity: self.enabled ? 1 : 0.4
    background: Rectangle {
        color: self.enabled && self.hovered ? '#00DD6E' : '#00B45A'
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
    contentItem: RowLayout {
        spacing: image.visible ? 10 : 0
        HSpacer {
        }
        Image {
            id: image
            source: self.icon.source
            visible: image.status === Image.Ready
        }
        Label {
            font.pixelSize: 16
            font.weight: 600
            horizontalAlignment: Text.AlignHCenter
            text: self.text
            verticalAlignment: Text.AlignVCenter
        }
        HSpacer {
        }
    }
}
