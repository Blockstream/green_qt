import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal loginFinished(Context context)
    required property Wallet wallet
    StackView.onDeactivated: {
        pin_field.clear()
    }
    StackView.onActivating: {
        pin_field.clear()
        pin_field.enabled = true
    }
    id: self
    padding: 60
    title: self.wallet.name
    LoginController {
        id: controller
        wallet: self.wallet
        onInvalidPin: {
            pin_field.clear()
            pin_field.enabled = true
        }
        onSessionError: (error) => {
            console.log('got session error:', error)
        }

        onLoginFinished: (context) => self.loginFinished(context)
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
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.family: 'SF Compact Display'
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
            font.family: 'SF Compact Display'
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
            Layout.bottomMargin: 45
            font.family: 'SF Compact Display'
            font.pixelSize: 12
            font.weight: 600
            horizontalAlignment: Qt.AlignHCenter
            text: {
                if (!self.wallet.hasPinData) {
                    return qsTrId('id_pin_access_disabled')
                } else switch (self.wallet.loginAttemptsRemaining) {
                    case 0: return qsTrId('id_no_attempts_remaining')
                    case 1: return qsTrId('id_last_attempt_if_failed_you_will')
                    case 2: return qsTrId('id_attempts_remaining_d').arg(self.wallet.loginAttemptsRemaining)
                    default: ''
                }
            }
            wrapMode: Label.WordWrap
        }
        PinPadButton {
            Layout.alignment: Qt.AlignCenter
            onClicked: pin_field.openPad()
        }
        VSpacer {
        }
    }
    footer: StackViewPage.Footer {
        contentItem: ColumnLayout {
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/house.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 600
                text: qsTrId('id_make_sure_to_be_in_a_private')
            }
        }
    }

    component PinPadButton: AbstractButton {
        id: pin_pad_button
        leftPadding: 13
        topPadding: 12
        bottomPadding: 12
        rightPadding: 13
        background: Rectangle {
            border.width: 1
            border.color: '#FFF'
            color: 'transparent'
            radius: 8
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 12
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                visible: pin_pad_button.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: 8
            Image {
                source: 'qrc:/svg2/hand.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.family: 'SF Compact Display'
                font.pixelSize: 16
                font.weight: 700
                text: 'Pin Pad'
                wrapMode: Label.Wrap
            }
        }
    }
}
