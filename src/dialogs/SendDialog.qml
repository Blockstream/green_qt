import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import '..'

ControllerDialog {
    title: qsTr('id_send')

    controller: SendTransactionController {
        address: send_view.address
        amount: send_view.amount
        sendAll: send_view.sendAll
    }

    initialItem: SendView {
        id: send_view
    }
}
