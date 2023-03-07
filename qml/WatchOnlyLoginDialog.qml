import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ControllerDialog {
    required property Network network

    id: self
    icon: UtilJS.iconFor(self.network)
    title: qsTrId('id_watchonly_login')

    controller: WatchOnlyLoginController {
        id: controller
        network: self.network
        username: username_field.text
        password: password_field.text
        saveWallet: remember_checkbox.checked
        onLoginFinished: (wallet) => {
            if (controller.saveWallet) {
                Analytics.recordEvent('wallet_restore_watch_only', AnalyticsJS.segmentationSession(wallet))
            }
            window.navigation.push({ wallet: wallet.id })
            self.accept()
        }
        onLoginFailed: self.contentItem.ToolTip.show(qsTrId('id_user_not_found_or_invalid'), 3000);
    }

    ColumnLayout {
        enabled: !controller.dispatcher.busy
        spacing: constants.s1
        Label {
            text: qsTrId('id_username')
        }
        GTextField {
            Layout.fillWidth: true
            id: username_field
            focus: true
            onAccepted: login_action.trigger()
        }
        Label {
            text: qsTrId('id_password')
        }
        GTextField {
            Layout.fillWidth: true
            id: password_field
            echoMode: TextField.Password
            onAccepted: login_action.trigger()
        }
        RowLayout {
            CheckBox {
                id: remember_checkbox
                text: qsTrId('id_remember_me')
                checked: true
            }
            HSpacer {
            }
            GButton {
                highlighted: true
                action: Action {
                    id: login_action
                    text: qsTrId('id_login');
                    enabled: controller.valid
                    onTriggered: controller.login()
                }
            }
        }
    }

    AnalyticsView {
        active: self.opened
        name: 'OnBoardWatchOnlyCredentials'
        segmentation: AnalyticsJS.segmentationSession(controller.wallet)
    }
}
