import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

AbstractDialog {
    required property Wallet wallet

    property bool active: self.wallet.activities.length > 0 || (self.wallet.session && self.wallet.session.activities.length > 0)

    id: self
    icon: icons[self.wallet.network.key]
    focus: true
    title: self.wallet.name

    closePolicy: self.active ? Dialog.NoAutoClose : AbstractDialog.closePolicy
    enableRejectButton: !self.active

    AnalyticsView {
        name: 'Login'
        active: self.opened
        segmentation: segmentationSession(self.wallet)
    }

    Connections {
        target: self.wallet
        function onActivityCreated(activity) {
            if (activity instanceof WalletAuthenticateActivity) {
                const view = foo.createObject(activities_row, { activity })
                activity.failed.connect(() => {
                    view.destroy()
                })
                activity.finished.connect(() => {
                    view.destroy()
                    stack_view.push(loading_view)
                })
            }
        }
    }
    Connections {
        target: self.wallet.session
        function onActivityCreated(activity) {
            if (activity instanceof SessionTorCircuitActivity) {
                session_tor_cirtcuit_view.createObject(activities_row, { activity })
            } else if (activity instanceof SessionConnectActivity) {
                session_connect_view.createObject(activities_row, { activity })
            }
        }
    }

    Component {
        id: foo
        RowLayout {
            required property WalletAuthenticateActivity activity
            id: self
            VSpacer {}
            BusyIndicator {
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: 'Authenticating'
            }
            VSpacer {}
        }
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
                    password_error.error = qsTrId('id_user_not_found_or_invalid')
                    password_field.enabled = true
                    password_field.clear()
                    password_field.forceActiveFocus()
                }
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
        GPane {
            LoginWithPinController {
                wallet: self.wallet
                pin: pin_view.pin.value
            }
            Connections {
                target: self.wallet
                function onLoginAttemptsRemainingChanged(loginAttemptsRemaining) {
                    pin_view.clear()
                }
            }
            contentItem: ColumnLayout {
                spacing: 12
                PinView {
                    id: pin_view
                    Layout.alignment: Qt.AlignHCenter
                    enabled: !self.active && self.wallet.loginAttemptsRemaining > 0 && self.wallet.hasPinData
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
                            default: return qsTrId('id_enter_pin')
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
                    onClicked: window.navigation.go('/restore', { network: self.wallet.network.key })
                }
            }
        }
    }

    property Item loading_view: ColumnLayout {
        spacing: 8
        VSpacer {}
        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: {
                const count = self.wallet.activities.length
                if (count > 0) {
                    const activity = self.wallet.activities[count - 1]
                    if (activity instanceof WalletUpdateAccountsActivity) {
                        return qsTrId('id_loading_accounts')
                    }
                    if (activity instanceof WalletRefreshAssets) {
                        return qsTrId('id_loading_assets')
                    }
                    if (activity instanceof AccountGetTransactionsActivity) {
                        return qsTrId('id_loading_transactions')
                    }
                }
                return qsTrId('id_loading_wallet')
            }
        }
        VSpacer {}
    }

    footer: DialogFooter {
        GPane {
            visible: self.wallet.loginAttemptsRemaining > 0
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
    }
}
