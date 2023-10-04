import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal registerFinished(Context context)
    required property string pin
    required property var mnemonic
    id: self
    leftItem: null
    StackView.onActivated: controller.active = true
    SignupController {
        id: controller
        pin: self.pin
        mnemonic: self.mnemonic
        network: NetworkManager.network('electrum-mainnet')
        onRegisterFinished: (context) => { self.registerFinished(context) }
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            running: !controller.wallet
        }
        VSpacer {
        }
    }
}
