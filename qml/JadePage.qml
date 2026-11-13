import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Layouts

// Logs in with a Jade that went through JadeConnectFlow, which runs the
// genuine check and unlocks it.
StackViewPage {
    signal loginFinished(Context context)
    signal detailsClicked()
    required property JadeDevice device
    // The context the device was unlocked on, if any, to log in with.
    property Context context: null
    id: self
    footer: null
    padding: 60
    title: self.device.name
    rightItem: RowLayout {
        Layout.topMargin: 20
        spacing: 20
        CircleButton {
            icon.source: 'qrc:/svg2/info.svg'
            visible: Qt.application.arguments.includes('--debugjade')
            onClicked: self.detailsClicked()
        }
        WalletOptionsButton {
            wallet: null
            onCloseClicked: self.closeClicked()
        }
    }

    contentItem: Item {
        GStackView {
            anchors.fill: parent
            anchors.leftMargin: self.padding
            anchors.rightMargin: self.padding
            anchors.bottomMargin: self.padding
            id: stack_view
            initialItem: JadeLoginView {
                context: self.context
                device: self.device
                onLoginFinished: (context) => self.loginFinished(context)
                onLoginFailed: self.loginFinished(context)
            }
        }
    }
}
