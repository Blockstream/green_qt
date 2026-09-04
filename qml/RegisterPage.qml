import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal loginStarted()
    signal loginStopped()
    signal registerFinished(Context context)
    required property var mnemonic
    property bool signupStarted: false
    function startSignup(deployment) {
        if (self.signupStarted) return
        self.signupStarted = true
        controller.signup(deployment)
    }
    StackView.onActivated: {
        if (self.signupStarted) return
        if (Settings.enableTestnet) {
            deployment_dialog.createObject(self).open()
        } else {
            self.startSignup('mainnet')
        }
    }
    id: self
    padding: 0
    leftItem: Item {
    }
    SignupController {
        id: controller
        mnemonic: self.mnemonic
        onNetworkLoginActiveChanged: {
            if (controller.networkLoginActive) {
                self.loginStarted()
            } else {
                self.loginStopped()
            }
        }
        onRegisterFinished: (context) => {
            self.registerFinished(context)
        }
    }
    BusyIndicator {
        Layout.alignment: Qt.AlignCenter
        running: !controller.wallet
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        font.pixelSize: 22
        font.weight: 600
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_creating_wallet')
        wrapMode: Label.WordWrap
    }

    Component {
        id: deployment_dialog
        DeploymentDialog {
            onCancel: self.popPage()
            onDeploymentSelected: (deployment) => self.startSignup(deployment)
        }
    }
}
