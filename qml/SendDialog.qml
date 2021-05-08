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
    wallet: send_dialog.account.wallet

    controller: SendController {
        id: send_controller
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

    doneComponent: WizardPage {
        actions: Action {
            text: qsTrId('id_ok')
            onTriggered: send_dialog.accept()
        }
        contentItem: ColumnLayout {
            spacing: constants.p1
            VSpacer {}
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: 'qrc:/svg/check.svg'
                sourceSize.width: 64
                sourceSize.height: 64
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                id: doneLabel
                text: doneText
                font.pixelSize: 20
            }
            CopyableLabel {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: constants.p1
                font.pixelSize: 12
                delay: 50
                text: send_controller.signedTransaction.data.txhash
            }
            VSpacer {}
        }
    }
}
