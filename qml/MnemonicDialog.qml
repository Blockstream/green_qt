import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: dialog
    controller: Controller {
        wallet: dialog.wallet
    }
    Component.onCompleted: controller.getCredentials()
    title: qsTrId('id_mnemonic')
    initialItem: null
    doneComponent: GPane {
        property Handler handler
        contentItem: StackLayout {
            currentIndex: qrcode_switch.checked ? 1 : 0
            MnemonicView {
                mnemonic: handler.mnemonic.split(' ')
            }
            QRCode {
                id: qrcode
                implicitHeight: 200
                implicitWidth: 200
                text: handler.mnemonic
            }
        }
    }

    footer: RowLayout {
        spacing: 60
        ProgressBar {
            Layout.fillWidth: true
            Layout.margins: 20
            NumberAnimation on value {
                paused: dialog.hovered
                duration: 10000
                from: 1
                to: 0
                loops: 1
                onFinished: close()
            }
        }
        GSwitch {
            id: qrcode_switch
            checked: false
            Layout.margins: 20
            text: qsTrId('id_show_qr_code')
        }
    }
}
