import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

GPane {
    required property Wallet wallet

    id: self

    WatchOnlyLoginController {
        id: watchonly_login_controller
        wallet: self.wallet
        password: password_field.text
        onUnauthorized: {
            Analytics.recordEvent('failed_wallet_login', AnalyticsJS.segmentationWalletLogin(self.wallet, { method: 'watch_only' }))
            password_error.error = qsTrId('id_user_not_found_or_invalid')
            password_field.enabled = true
            password_field.clear()
            password_field.forceActiveFocus()
        }
        onLoginDone: Analytics.recordEvent('wallet_login', AnalyticsJS.segmentationWalletLogin(self.wallet, { method: 'watch_only' }))
    }
    Action {
        id: login_action
        onTriggered: {
            password_error.error = undefined
            password_field.enabled = false
            watchonly_login_controller.login()
        }
    }
    enabled: !controller.session
    contentItem: GridLayout {
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
