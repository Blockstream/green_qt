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
    icon: icons[self.wallet.network.id]
    focus: true
    title: self.wallet.name
    width: 350
    height: 450

    closePolicy: self.active ? Dialog.NoAutoClose : AbstractDialog.closePolicy
    enableRejectButton: !self.active

    LoginWithPinController {
        id: controller
        wallet: self.wallet
        pin: pin_view.pin.value
    }

    Connections {
        target: self.wallet
        function onLoginAttemptsRemainingChanged(loginAttemptsRemaining) {
            pin_view.clear()
        }
    }
    Connections {
        target: self.wallet
        function onActivityCreated(activity) {
            console.log(controller, 'activity created', activity)
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
        initialItem: Pane {
            background: null
            contentItem: ColumnLayout {
                spacing: 8
                PinView {
                    id: pin_view
                    Layout.alignment: Qt.AlignHCenter
                    enabled: !self.active
                }
                Label {
                    Layout.topMargin: 8
                    Layout.maximumWidth: 250
                    Layout.minimumHeight: 25
                    Layout.alignment: Qt.AlignHCenter
                    opacity: self.wallet.activities.length === 0 ? 1 : 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    text: switch (self.wallet.loginAttemptsRemaining) {
                        case 0: return qsTrId('id_no_attempts_remaining')
                        case 1: return qsTrId('id_last_attempt_if_failed_you_will')
                        case 2: return qsTrId('id_attempts_remaining_d').arg(self.wallet.loginAttemptsRemaining)
                        default: return qsTrId('id_enter_pin')
                    }
                    Behavior on opacity { NumberAnimation {} }
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
                        return 'Loading accounts'
                    }
                    if (activity instanceof WalletRefreshAssets) {
                        return 'Loading assets'
                    }
                    if (activity instanceof AccountGetTransactionsActivity) {
                        return 'Loading transactions'
                    }
                }
                return 'Loading wallet'
            }
        }
        VSpacer {}
    }

    footer: DialogFooter {
        Pane {
            Layout.minimumHeight: 48
            background: null
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
        Button {
            highlighted: true
            Layout.minimumWidth: 250
            Layout.minimumHeight: 25
            visible: self.wallet.loginAttemptsRemaining === 0
            text: 'Restore Wallet'
            onClicked: pushLocation(`/${self.wallet.network.id}/restore`)
        }
    }
}
