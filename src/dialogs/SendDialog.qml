import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import '..'

Dialog {
    property alias account: controller.account

    title: qsTr('id_send')
    width: 420
    height: 500
    horizontalPadding: 50
    anchors.centerIn: parent
    modal: true
    clip: true

    onRejected: send_view.state = ''

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

    StackView {
        id: stack_view
        anchors.fill: parent
        initialItem: SendView {
            id: send_view
        }
    }

    footer: DialogButtonBox {
        Repeater {
            model: stack_view.currentItem.actions || []
            Button {
                flat: true
                action: modelData
            }
        }
    }
}
