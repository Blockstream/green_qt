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
    RowLayout {
        spacing: 20
        MnemonicView {
            columns: controller.context.mnemonic.length > 12 ? 4 : 2
            mnemonic: controller.context.mnemonic
        }
        QRCode {
            id: qrcode
            implicitHeight: 280
            implicitWidth: 280
            text: controller.context.mnemonic.join(' ')
        }
    }
}
