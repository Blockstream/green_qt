import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
    id: self
    background: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            z: -1
            visible: self.visualFocus
        }
    }
    contentItem: RowLayout {
        spacing: 10
        HSpacer {
        }
        Image {
            source: 'qrc:/svg2/printer.svg'
        }
        Label {
            color: '#FFF'
            font.pixelSize: 12
            font.weight: 556
            text: self.text
        }
        HSpacer {
        }
    }
    onClicked: WalletManager.printBackupTemplate()
}
