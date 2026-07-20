import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context

    id: self
    title: 'AMP2 (Testnet)'
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }

    CreateAccountController {
        id: controller
        context: self.context
        network: NetworkManager.network('electrum-testnet-liquid')
        type: 'amp2'
        onCreated: self.closeClicked()
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        Label {
            Layout.fillWidth: true
            text: 'Create an AMP2 account to manage AMP2 assets.'
            font.pixelSize: 13
            color: '#6F6F6F'
            wrapMode: Label.Wrap
        }
        ErrorPane {
            Layout.topMargin: 10
            error: controller.error
        }
        VSpacer {
        }
    }

    footerItem: ColumnLayout {
        PrimaryButton {
            Layout.fillWidth: true
            text: 'Enable AMP2 Account'
            busy: controller.busy
            enabled: !controller.busy
            onClicked: controller.create()
        }
    }
}
