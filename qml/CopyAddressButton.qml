import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    property string content: self.text
    id: self
    padding: 10
    font.pixelSize: 12
    font.weight: 600
    background: Item {
        Rectangle {
            anchors.fill: parent
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            radius: 8
            visible: self.visualFocus
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: self.visualFocus ? 4 : 0
            color: Qt.alpha(Qt.darker('#13161D'), 0.6)
            radius: self.visualFocus ? 4 : 8
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
            font: self.font
            text: self.text
        }
    }
    onClicked: {
        Clipboard.copy(self.content)
        timer.restart()
    }
    Timer {
        id: timer
        repeat: false
        interval: 1000
    }
}
