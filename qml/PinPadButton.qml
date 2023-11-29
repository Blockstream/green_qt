import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: self
    leftPadding: 13
    topPadding: 12
    bottomPadding: 12
    rightPadding: 13
    opacity: enabled ? 1 : 0.5
    background: Rectangle {
        border.width: 1
        border.color: '#FFF'
        color: 'transparent'
        radius: 8
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 12
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            visible: self.visualFocus
        }
    }
    contentItem: RowLayout {
        spacing: 8
        Image {
            source: 'qrc:/svg2/hand.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 16
            font.weight: 700
            text: 'Pin Pad'
            wrapMode: Label.Wrap
        }
    }
}
