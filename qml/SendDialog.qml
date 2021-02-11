import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

ControllerDialog {
    id: send_dialog
    title: qsTrId('id_send')
    icon: 'qrc:/svg/send.svg'
    autoDestroy: true
    required property Account account

    controller: SendController {
        account: send_dialog.account
        balance: send_view.balance
        address: send_view.address
        sendAll: send_view.sendAll
    }

    doneText: qsTrId('id_transaction_sent')
    minimumWidth: 500
    minimumHeight: 300

    initialItem: SendView {
        id: send_view
    }
}
