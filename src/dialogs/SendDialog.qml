import Blockstream.Green 0.1
import QtQuick.Controls 2.13
import '..'

Dialog {
    property alias account: send_view.account
    title: qsTr('id_send')
    font.family: dinpro.name
    width: 420
    horizontalPadding: 50
    anchors.centerIn: parent
    modal: true

    SendView {
        id: send_view
        width: parent.width
    }

    footer: DialogButtonBox {
        Button {
            action: send_view.acceptAction
            flat: true
        }
    }
}
