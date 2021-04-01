import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

WalletDialog {
    title: qsTrId('id_mnemonic')
    contentItem: Pane {
        background: MouseArea {
            id: mouse_area
            hoverEnabled: true
        }
        contentItem: StackLayout {
            currentIndex: qrcode_switch.checked ? 1 : 0
            MnemonicView {
                mnemonic: wallet.mnemonic
            }
            QRCode {
                id: qrcode
                implicitHeight: 200
                implicitWidth: 200
                text: wallet.mnemonic.join(' ')
            }
        }
    }

    footer: RowLayout {
        spacing: 60
        ProgressBar {
            Layout.fillWidth: true
            Layout.margins: 20
            NumberAnimation on value {
                paused: mouse_area.containsMouse
                duration: 10000
                from: 1
                to: 0
                loops: 1
                onFinished: close()
            }
        }
        Switch {
            id: qrcode_switch
            checked: false
            Layout.margins: 20
            text: qsTrId('id_show_qr_code')
        }
    }
}
