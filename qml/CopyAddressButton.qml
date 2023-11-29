import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    required property string address
    id: self
    padding: 10
    background: Rectangle {
        color: '#13161D'
        radius: 4
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 8
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            opacity: self.visualFocus ? 1 : 0
        }
    }
    contentItem: RowLayout {
        spacing: 10
        Item {
            Layout.minimumHeight: 22
            Layout.minimumWidth: 22
            Image {
                anchors.centerIn: parent
                source: timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
            }
        }
        Label {
            font.pixelSize: 12
            font.weight: 600
            text: 'Copy Address'
        }
    }
    onClicked: {
        Clipboard.copy(self.address)
        timer.restart()
    }
    Timer {
        id: timer
        repeat: false
        interval: 1000
    }
}
