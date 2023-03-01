import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

GPane {
    required property Wallet wallet

    id: self

    LoginWithPinController {
        id: controller
        wallet: self.wallet
        pin: pin_view.pin.value
        onLoginDone: {
            Analytics.recordEvent('wallet_login', AnalyticsJS.segmentationWalletLogin(self.wallet, {
                method: 'pin'
            }))
        }
        onLoginFailed: {
            Analytics.recordEvent('failed_wallet_login', AnalyticsJS.segmentationSession(self.wallet))
        }
    }
    Connections {
        target: self.wallet
        function onLoginAttemptsRemainingChanged(loginAttemptsRemaining) {
            Analytics.recordEvent('failed_wallet_login', AnalyticsJS.segmentationWalletLogin(self.wallet, { method: 'pin' }))
            pin_view.clear()
        }
    }
    contentItem: ColumnLayout {
        spacing: 12
        AlertView {
            alert: AnalyticsAlert {
                screen: 'Login'
                network: self.wallet.network.id
            }
        }
        PinView {
            focus: true
            id: pin_view
            Layout.alignment: Qt.AlignHCenter
            enabled: !self.active && self.wallet.loginAttemptsRemaining > 0 && self.wallet.hasPinData && !controller.pin
        }
        Label {
            Layout.preferredWidth: 0
            Layout.fillWidth: true
            padding: 8
            background: Rectangle {
                visible: !self.wallet.hasPinData || self.wallet.loginAttemptsRemaining < 3
                radius: 4
                color: constants.r500
            }
            font.capitalization: Font.AllUppercase
            font.styleName: 'Medium'
            font.pixelSize: 10
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
            wrapMode: Text.WordWrap
        }
        GButton {
            Layout.alignment: Qt.AlignHCenter
            highlighted: true
            large: true
            visible: self.wallet.loginAttemptsRemaining === 0 || !self.wallet.hasPinData
            text: qsTrId('id_restore_wallet')
            onClicked: navigation.set({ flow: 'restore', network: self.wallet.network.key })
        }
    }
}
