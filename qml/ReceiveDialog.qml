import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

WalletDialog {
    title: qsTrId('id_receive')
    onClosed: destroy()

    header: Item {
        implicitHeight: 48
        Label {
            text: title
            anchors.left: parent.left
            anchors.margins: 16
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 16
            font.capitalization: Font.AllUppercase
        }
        ToolButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 8
            icon.source: 'svg/cancel.svg'
            icon.width: 16
            icon.height: 16
            onClicked: reject()
        }
    }
    ReceiveView { }
}
