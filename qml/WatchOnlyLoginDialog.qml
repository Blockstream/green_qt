import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

AbstractDialog {
    required property Network network
    id: self
    icon: icons[self.network.id]
    title: qsTrId('id_watchonly_login')
    onClosed: destroy()
    WatchOnlyLoginController {
        id: controller
        network: self.network
        username: username_field.text
        password: password_field.text
        onWalletChanged: {
            navigation.go(`/${wallet.network.id}/${wallet.id}`)
            self.close()
        }
        onActivityCreated: {
            if (activity instanceof SessionTorCircuitActivity) {
                session_tor_cirtcuit_view.createObject(activities_row, { activity })
            } else if (activity instanceof SessionConnectActivity) {
                session_connect_view.createObject(activities_row, { activity })
            }
        }
        onUnauthorized: self.contentItem.ToolTip.show(qsTrId('id_unauthorized'), 3000);
    }

    contentItem: GridLayout {
        enabled: !controller.session
        columns: 2
        Label {
            text: qsTrId('id_username')
        }
        TextField {
            id: username_field
            focus: true
        }
        Label {
            text: qsTrId('id_password')
        }
        TextField {
            id: password_field
            echoMode: TextField.Password
        }
    }

    footer: DialogFooter {
        GPane {
            background: null
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
