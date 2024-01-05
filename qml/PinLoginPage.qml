import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal loginFinished(Context context)
    signal restoreClicked()
    signal removeClicked()
    signal closeClicked()
    required property Wallet wallet
    StackView.onDeactivated: {
        pin_field.clear()
    }
    StackView.onActivating: {
        pin_field.clear()
        pin_field.enabled = true
        pin_field.forceActiveFocus()
    }
    id: self
    padding: 60
    title: self.wallet.name
    LoginController {
        id: controller
        wallet: self.wallet
        onInvalidPin: {
            pin_field.clear()
            pin_field.enabled = self.wallet.loginAttemptsRemaining > 0
        }
        onLoginFinished: (context) => self.loginFinished(context)
    }
    rightItem: WalletOptionsButton {
        wallet: self.wallet
        onRemoveClicked: self.removeClicked()
        onCloseClicked: self.closeClicked()
    }
    contentItem: GStackView {
        id: stack_view
        initialItem: ColumnLayout {
            Timer {
                interval: 2000
                running: self.wallet.loginAttemptsRemaining === 0
                onTriggered: stack_view.push(no_attempts_view)
            }
            VSpacer {
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 26
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: 'Enter your 6-digit PIN to Access your Wallet'
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.maximumWidth: 450
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                opacity: 0.4
                text: `You'll need your PIN to log in to your wallet. This PIN secures the wallet on this device only.`
                wrapMode: Label.Wrap
            }
            PinField {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 36
                id: pin_field
                focus: true
                onPinEntered: (pin) => {
                    pin_field.enabled = false
                    controller.loginWithPin(pin)
                }
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 30
                font.pixelSize: 12
                font.weight: 600
                horizontalAlignment: Qt.AlignHCenter
                text: {
                    switch (self.wallet.loginAttemptsRemaining) {
                    case 0: return qsTrId('id_no_attempts_remaining')
                    case 1: return qsTrId('id_last_attempt_if_failed_you_will')
                    case 2: return qsTrId('id_attempts_remaining_d').arg(self.wallet.loginAttemptsRemaining)
                    default: return ''
                    }
                }
                wrapMode: Label.WordWrap
            }
            PinPadButton {
                Layout.alignment: Qt.AlignCenter
                enabled: pin_field.enabled
                target: pin_field
            }
            VSpacer {
            }
        }
    }
    footerItem: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/house.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_make_sure_to_be_in_a_private')
        }
    }
    Component {
        id: no_attempts_view
        ColumnLayout {
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/warning.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 45
                font.pixelSize: 14
                font.weight: 500
                horizontalAlignment: Qt.AlignHCenter
                text: qsTrId('id_youve_entered_an_invalid_pin')
            }
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_restore_with_recovery_phrase')
                onClicked: self.restoreClicked()
            }
            VSpacer {
            }
        }
    }
}
