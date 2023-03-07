import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    required property Task task
    id: self
    contentItem: ColumnLayout {
        StackLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            currentIndex: qrcode_switch.checked ? 1 : 0
            ColumnLayout {
                MnemonicView {
                    mnemonic: task.result.result.mnemonic.split(' ')
                }
                Spacer {
                }
            }
            ColumnLayout {
                QRCode {
                    id: qrcode
                    Layout.alignment: Qt.AlignCenter
                    implicitHeight: 200
                    implicitWidth: 200
                    text: task.result.result.mnemonic
                }
                Spacer {
                }
            }
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
