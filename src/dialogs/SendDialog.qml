import Blockstream.Green 0.1
import QtQuick.Controls 2.13
import '..'

Dialog {
    title: qsTr('id_send')
    font.family: dinpro.name
    width: 420
    horizontalPadding: 50
    anchors.centerIn: parent
    modal: true

    SendView {
        width: parent.width
    }
}
