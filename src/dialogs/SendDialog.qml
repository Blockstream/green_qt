import Blockstream.Green 0.1
import QtQuick.Controls 2.13
import '..'

Dialog {
    property alias account: controller.account

    title: qsTr('id_send')
    font.family: dinpro.name
    width: 420
    horizontalPadding: 50
    anchors.centerIn: parent
    modal: true

    SendTransactionController {
        id: controller
        address: send_view.address
        amount: send_view.amount
        sendAll: send_view.sendAll

        onCodeRequested: {
            send_view.methods = result.methods
            send_view.methods_dialog.open()
        }

        onEnterResolveCode: swipe_view.currentIndex = 1

        onEnterDone: if (result.action === 'send_raw_tx') {
            _result = result.result
            swipe_view.currentIndex = 2
        }
    }

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
