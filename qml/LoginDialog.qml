import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

AbstractDialog {
    required property Wallet wallet

    property bool active: self.wallet.activities.length > 0 || (self.wallet.session && self.wallet.session.connecting)

    id: self
    icon: iconFor(self.wallet)
    focus: true
    title: self.wallet.name

    closePolicy: self.active ? Dialog.NoAutoClose : AbstractDialog.closePolicy
    enableRejectButton: !self.active

    AnalyticsView {
        name: 'Login'
        active: self.opened
        segmentation: segmentationSession(self.wallet)
    }

    contentItem: StackView {
        id: stack_view
        implicitHeight: currentItem.implicitHeight
        implicitWidth: currentItem.implicitWidth
        onCurrentItemChanged: {
            currentItem.forceActiveFocus()
        }
        initialItem: self.wallet.watchOnly ? login_with_password_view : login_with_pin_view
    }

    Component {
        id: login_with_password_view
        GPane {
            WatchOnlyLoginController {
                id: watchonly_login_controller
                wallet: self.wallet
                password: password_field.text
                onUnauthorized: {
                    Analytics.recordEvent('failed_wallet_login', segmentationWalletLogin(self.wallet, { method: 'watch_only' }))
                    password_error.error = qsTrId('id_user_not_found_or_invalid')
                    password_field.enabled = true
                    password_field.clear()
                    password_field.forceActiveFocus()
                }
                onLoginDone: Analytics.recordEvent('wallet_login', segmentationWalletLogin(self.wallet, { method: 'watch_only' }))
            }
            Action {
                id: login_action
                onTriggered: {
                    password_error.error = undefined
                    password_field.enabled = false
                    watchonly_login_controller.login()
                }
            }
            contentItem: GridLayout {
                enabled: !controller.session
                columns: 2
                columnSpacing: 12
                rowSpacing: 12
                Label {
                    text: qsTrId('id_username')
                }
                Label {
                    text: self.wallet.username
                }
                Label {
                    text: qsTrId('id_password')
                }
                GTextField {
                    Layout.fillWidth: true
                    id: password_field
                    echoMode: TextField.Password
                    focus: true
                    onAccepted: login_action.trigger()
                }
                Label {
                }
                FixedErrorBadge {
                    id: password_error
                }
                GButton {
                    Layout.columnSpan: 2
                    Layout.alignment: Qt.AlignHCenter
                    highlighted: true
                    large: true
                    text: qsTrId('id_login')
                    onClicked: login_action.trigger()
                    enabled: watchonly_login_controller.valid && !watchonly_login_controller.session
                }
            }
        }
    }

    Component {
        id: login_with_pin_view
        LoginWithPinView {
            wallet: self.wallet
        }
    }

    footer: DialogFooter {
        SessionBadge {
            visible: self.wallet.loginAttemptsRemaining > 0
            session: self.wallet.session
        }
        HSpacer {}
    }
}
