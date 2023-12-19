import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    required property bool isCurrent
    Layout.fillWidth: true
    id: self
    padding: 16
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.isCurrent
            color: Qt.rgba(1, 1, 1, 0.05)
            Rectangle {
                visible: self.isCurrent
                width: 1
                color: 'white'
                x: parent.width - 2
                height: parent.height
            }
        }
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 4
            anchors.fill: parent
            anchors.margins: 4
            z: -1
            opacity: self.visualFocus ? 1 : 0
        }
    }
    contentItem: RowLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: self.icon.source
            sourceSize.width: self.icon.width
            sourceSize.height: self.icon.height
        }
    }
}
