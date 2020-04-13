import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

ControllerDialog {
    title: qsTr('id_send')

    controller: SendTransactionController {
        balance: send_view.balance
        address: send_view.address
        sendAll: send_view.sendAll
    }

    doneText: qsTr('id_transaction_sent')
    minimumWidth: 500
    minimumHeight: 300

    initialItem: SendView {
        id: send_view
    }
}
