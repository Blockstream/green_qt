import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: self
    controller: Controller {
        id: controller
        context: self.wallet.context
    }

    title: qsTrId('id_recovery_phrase')
    ColumnLayout {
        Spacer {
        }
        StackLayout {
            Layout.alignment: Qt.AlignCenter
            currentIndex: qrcode_switch.checked ? 1 : 0
            MnemonicView {
                mnemonic: controller.context.mnemonic
            }
            QRCode {
                id: qrcode
                implicitHeight: 200
                implicitWidth: 200
                text: controller.context.mnemonic.join(' ')
            }
        }
        Spacer {
        }
        RowLayout {
            Layout.fillHeight: false
            ProgressBar {
                Layout.fillWidth: true
                Layout.maximumWidth: 100
                NumberAnimation on value {
                    paused: self.hovered
                    duration: 10000
                    from: 1
                    to: 0
                    loops: 1
                    onFinished: close()
                }
            }
            HSpacer {
            }
            GSwitch {
                id: qrcode_switch
                checked: false
                text: qsTrId('id_show_qr_code')
            }
        }
    }
}
