import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

import "analytics.js" as AnalyticsJS

AbstractDialog {
    required property Network network

    id: self
    icon: iconFor(self.network)
    title: qsTrId('id_watchonly_login')
    onClosed: destroy()
    contentItem: GridLayout {
        enabled: !controller.session
        columns: 2
        columnSpacing: 12
        rowSpacing: 12
        Label {
            text: qsTrId('id_username')
        }
        GTextField {
            Layout.fillWidth: true
            id: username_field
            focus: true
        }
        Label {
            text: qsTrId('id_password')
        }
        GTextField {
            Layout.fillWidth: true
            id: password_field
            echoMode: TextField.Password
        }
        CheckBox {
            Layout.columnSpan: 2
            id: remember_checkbox
            text: qsTrId('id_remember_me')
            checked: true
        }
    }
    footer: DialogFooter {
        HSpacer {
        }
        GButton {
            large: true
            text: qsTrId('id_login');
            enabled: controller.valid && !controller.session
            onClicked: controller.login()
        }
    }
    WatchOnlyLoginController {
        id: controller
        network: self.network
        username: username_field.text
        password: password_field.text
        saveWallet: remember_checkbox.checked
        onWalletChanged: {
            if (controller.saveWallet) {
                Analytics.recordEvent('wallet_restore_watch_only', AnalyticsJS.segmentationSession(wallet))
            }
            window.navigation.go(`/${wallet.network.key}/${wallet.id}`)
            self.accept()
        }
        onUnauthorized: self.contentItem.ToolTip.show(qsTrId('id_user_not_found_or_invalid'), 3000);
    }
    AnalyticsView {
        active: self.opened
        name: 'OnBoardWatchOnlyCredentials'
        segmentation: AnalyticsJS.segmentationSession(controller.wallet)
    }
}
