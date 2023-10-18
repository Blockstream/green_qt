import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal registerFinished(Context context)
    required property string pin
    required property var mnemonic
    StackView.onActivated: controller.active = true
    id: self
    padding: 0
    leftItem: Item {
    }
    SignupController {
        id: controller
        pin: self.pin
        mnemonic: self.mnemonic
        network: NetworkManager.network('electrum-mainnet')
        onRegisterFinished: (context) => { self.registerFinished(context) }
    }
    background: Item {
        Image {
            anchors.fill: parent
            anchors.margins: -constants.p3
            source: 'qrc:/svg2/onboard_background.svg'
            fillMode: Image.PreserveAspectCrop
        }
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
