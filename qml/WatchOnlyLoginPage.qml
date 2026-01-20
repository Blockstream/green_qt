import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal loginFinished(Context context)
    signal removeClicked()
    required property Wallet wallet
    StackView.onActivating: {
        password_field.clear()
        self.contentItem.enabled = true
    }
    objectName: "WatchOnlyLoginPage"
    AnalyticsView {
        name: 'Login'
        active: UtilJS.effectiveVisible(self)
        segmentation: AnalyticsJS.segmentationSession(Settings, null)
    }
    WatchOnlyLoginController {
        id: controller
        wallet: self.wallet
        password: password_field.text
        onLoginFinished: {
            self.loginFinished(controller.context)
        }
        onLoginFailed: error => {
            self.contentItem.enabled = true
            password_field.clear()
            password_field.forceActiveFocus()
            error_badge.error = error
        }
    }
    Action {
        id: login_action
        enabled: controller.valid
        onTriggered: {
            error_badge.clear()
            self.contentItem.enabled = false
            controller.login()
        }
    }
    id: self
    footer: null
    padding: 60
    leftItem: BackButton {
        text: qsTrId('id_wallets')
        onClicked: self.closeClicked()
        visible: WalletManager.wallets.length > 1
    }
    rightItem: WalletOptionsButton {
        wallet: self.wallet
        onRemoveClicked: self.removeClicked()
        onCloseClicked: self.closeClicked()
    }
    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.fillHeight: false
        Layout.fillWidth: false
        Layout.maximumWidth: 300
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 450
            Layout.preferredWidth: 0
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_watchonly_login')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 450
            Layout.preferredWidth: 0
            Layout.topMargin: 20
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_log_in_via_watchonly_to_receive')
            wrapMode: Label.Wrap
        }
        ColumnLayout {
            visible: !self.wallet.login.network.electrum
            FieldTitle {
                text: qsTrId('id_username')
            }
            UsernameField {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                text: self.wallet.login.username
                readOnly: true
            }
            FieldTitle {
                text: qsTrId('id_password')
            }
            PasswordField {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                id: password_field
                focus: true
                onAccepted: login_action.trigger()
                onTextEdited: error_badge.clear()
            }
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            id: error_badge
            pointer: false
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.topMargin: 40
            text: qsTrId('id_login')
            action: login_action
            busy: !(controller.monitor?.idle ?? true)
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.topMargin: 10
            font.pixelSize: 14
            font.weight: 600
            opacity: 0.4
            horizontalAlignment: Qt.AlignCenter
            text: 'You can find the right credentials in settings, after logging in with PIN.'
            wrapMode: Label.Wrap
        }
    }
}
