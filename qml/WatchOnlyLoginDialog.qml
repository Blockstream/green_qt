import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

AbstractDialog {
    required property Network network
    id: self
    icon: icons[self.network.key]
    title: qsTrId('id_watchonly_login')
    onClosed: destroy()
    WatchOnlyLoginController {
        id: controller
        network: self.network
        username: username_field.text
        password: password_field.text
        saveWallet: remember_checkbox.checked
        onWalletChanged: {
            window.navigation.go(`/${wallet.network.key}/${wallet.id}`)
            self.accept()
        }
        onActivityCreated: {
            if (activity instanceof SessionTorCircuitActivity) {
                session_tor_cirtcuit_view.createObject(activities_row, { activity })
            } else if (activity instanceof SessionConnectActivity) {
                session_connect_view.createObject(activities_row, { activity })
            }
        }
        onUnauthorized: self.contentItem.ToolTip.show(qsTrId('id_user_not_found_or_invalid'), 3000);
    }

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
        GPane {
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
        HSpacer {
        }
        GButton {
            large: true
            text: qsTrId('id_login');
            enabled: controller.valid && !controller.session
            onClicked: controller.login()
        }
    }
}
