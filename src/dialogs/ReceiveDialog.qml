import Blockstream.Green 0.1
import QtQuick.Controls 2.13
import '..'

Dialog {
    title: qsTr('id_receive')
    horizontalPadding: 150
    anchors.centerIn: parent
    modal: true

    ReceiveView { }
}
