import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal restoreFinished(Context context)
    signal alreadyRestored(Wallet wallet)
    signal mismatch()
    property Wallet wallet
    required property var mnemonic
    required property string password
    RestoreController {
        id: controller
        wallet: self.wallet
        mnemonic: self.mnemonic
        password: self.password
        onRestoreFinished: (context) => self.restoreFinished(context)
        onAlreadyRestored: (wallet) => self.alreadyRestored(wallet)
        onMismatch: self.mismatch()
    }
    StackView.onActivated: {
        if (self.wallet) {
            controller.restore(self.wallet.deployment)
        } else if (Settings.enableTestnet) {
            deployment_dialog.createObject(self).open()
        } else {
            controller.restore('mainnet')
        }
    }
    objectName: "RestoreCheckPage"
    id: self
    title: self.wallet?.name ?? ''
    leftItem: Item {
    }
    padding: 60
    BusyIndicator {
        Layout.alignment: Qt.AlignCenter
        running: true
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        font.pixelSize: 26
        font.weight: 600
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_restoring_your_wallet')
        wrapMode: Label.WordWrap
    }

    Component {
        id: deployment_dialog
        DeploymentDialog {
            onCancel: self.StackView.view.pop()
            onDeploymentSelected: (deployment) => controller.restore(deployment)
        }
    }
}
