import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

GridLayout {
    required property Wallet wallet

    id: self

    readonly property WatchOnlyLoginController controller: WatchOnlyLoginController {
        id: controller
        wallet: self.wallet
        network: self.wallet.network
        username: self.wallet.username
        password: password_field.text
        onLoginFailed: {
            Analytics.recordEvent('failed_wallet_login', AnalyticsJS.segmentationWalletLogin(Settings, self.wallet, { method: 'watch_only' }))
            password_error.error = qsTrId('id_user_not_found_or_invalid')
            password_field.clear()
            password_field.forceActiveFocus()
        }
        onLoginFinished: {
            Analytics.recordEvent('wallet_login', AnalyticsJS.segmentationWalletLogin(Settings, self.wallet, { method: 'watch_only' }))
        }
    }

    Action {
        id: login_action
        onTriggered: {
            password_error.clear()
            self.controller.login()
        }
    }

    enabled: !controller.dispatcher.busy
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
        text: qsTrId('id_login')
        onClicked: login_action.trigger()
        enabled: controller.valid
    }
}
