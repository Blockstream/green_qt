import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

StackViewPage {
    signal loginFinished(Context context)
    required property Network network
    StackView.onActivating: {
        password_field.clear()
        self.contentItem.enabled = true
    }
    StackView.onActivated: Analytics.recordEvent('wallet_wo')
    AnalyticsView {
        active: true
        name: 'OnBoardWatchOnlyCredentials'
        segmentation: AnalyticsJS.segmentationSession(Settings, controller.context)
    }
    WatchOnlyLoginController {
        id: controller
        password: password_field.text
        username: username_field.text
        network: self.network
        persist: remember_checkbox.checked
        onLoginFinished: {
            self.loginFinished(controller.context)
            if (controller.persist) {
                Analytics.recordEvent('wallet_restore_watch_only', AnalyticsJS.segmentationSession(Settings, controller.context))
            }
        }
        onLoginFailed: error => {
            self.contentItem.enabled = true
            password_field.clear()
            password_field.forceActiveFocus()
            error_badge.raise(error)
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
    objectName: "MultisigWatchOnlyAddPage"
    id: self
    footer: null
    padding: 60
    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.fillHeight: false
        Layout.fillWidth: false
        Layout.maximumWidth: 300
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_login')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.4
            text: qsTrId('id_log_in_via_watchonly_to_receive')
            wrapMode: Label.Wrap
        }
        FieldTitle {
            text: qsTrId('id_username')
        }
        UsernameField {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            id: username_field
            focus: true
            onAccepted: login_action.trigger()
            onTextEdited: error_badge.clear()
        }
        FieldTitle {
            text: qsTrId('id_password')
        }
        PasswordField {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            id: password_field
            onAccepted: login_action.trigger()
            onTextEdited: error_badge.clear()
        }
        CheckBox {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            id: remember_checkbox
            checked: true
            text: qsTrId('id_remember_me')
            leftPadding: 12
            rightPadding: 12
            topPadding: 8
            bottomPadding: 8
            background: Rectangle {
                color: '#282D38'
                border.width: 1
                border.color: '#FFF'
                radius: 5
            }
            onCheckedChanged: error_badge.clear()
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
