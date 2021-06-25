import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

AbstractDialog {
    required property LedgerDeviceController controller
    readonly property Wallet wallet: controller.wallet

    property bool active: self.wallet.activities.length > 0 || (self.wallet.session && self.wallet.session.activities.length > 0)

    id: self
    icon: icons[controller.network.key]
    focus: true
    title: controller.device.name
    width: 350
    enableRejectButton: false
    closePolicy: self.active ? Dialog.NoAutoClose : AbstractDialog.closePolicy


//    LoginWithPinController {
//        id: controller
//        wallet: self.wallet
//        pin: pin_view.pin.value
//    }

//    Connections {
//        target: self.wallet
//        function onLoginAttemptsRemainingChanged(loginAttemptsRemaining) {
//            pin_view.clear()
//        }
//    }
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
        target: controller
        function onActivityCreated(activity) {
            if (activity instanceof SessionTorCircuitActivity) {
                session_tor_cirtcuit_view.createObject(activities_row, { activity })
            } else if (activity instanceof SessionConnectActivity) {
                session_connect_view.createObject(activities_row, { activity })
            }
        }
        function onStatusChanged(status) {
            if (status === 'done') {
                navigation.go(`/${controller.network.key}/${controller.wallet.id}`)
                self.reject()
            } else if (status === 'locked') {
                self.reject()
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
        initialItem: ProgressBar {
            indeterminate: controller.indeterminate
            value: controller.progress
            Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
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
            Layout.minimumHeight: 48
            background: null
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
        HSpacer {
        }
    }
}
