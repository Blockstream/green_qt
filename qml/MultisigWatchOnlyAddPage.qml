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
        onLoginFailed: {
            self.contentItem.enabled = true
            password_field.clear()
            password_field.forceActiveFocus()
            self.contentItem.ToolTip.show(qsTrId('id_user_not_found_or_invalid'), 3000);
        }
    }
    Action {
        id: login_action
        enabled: controller.valid
        onTriggered: {
            self.contentItem.enabled = false
            controller.login()
        }
    }
    id: self
    padding: 60
    contentItem: ColumnLayout {
        VSpacer {
        }
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
                Layout.topMargin: 20
                text: qsTrId('id_username')
            }
            UsernameField {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                id: username_field
                focus: true
                onAccepted: login_action.trigger()
            }
            FieldTitle {
                Layout.topMargin: 10
                text: qsTrId('id_password')
            }
            PasswordField {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                id: password_field
                onAccepted: login_action.trigger()
            }
            CheckBox {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 10
                id: remember_checkbox
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
            }
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.topMargin: 40
                text: qsTrId('id_login')
                action: login_action
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
        VSpacer {
        }
    }
}
