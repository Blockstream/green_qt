import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal registerFinished(Context context)
    required property var mnemonic
    StackView.onActivated: controller.signup("mainnet")
    id: self
    padding: 0
    leftItem: Item {
    }
    SignupController {
        id: controller
        mnemonic: self.mnemonic
        onRegisterFinished: (context) => self.registerFinished(context)
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            running: !controller.wallet
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.family: 'SF Compact Display'
            font.pixelSize: 22
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_creating_wallet')
            wrapMode: Label.WordWrap
        }
        VSpacer {
        }
    }
}
