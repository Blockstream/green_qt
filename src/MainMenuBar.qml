import Qt.labs.platform 1.1 as Labs
import QtQuick 2.12

Labs.MenuBar {
    Labs.Menu {
        title: qsTr('&File')
        Labs.MenuItem {
            text: qsTr('&New Wallet')
            shortcut: StandardKey.New
            onTriggered: create_wallet_action.trigger()
        }
    }

    Labs.Menu {
        Labs.MenuItemGroup {
            id: accounts_group
            exclusive: true
        }
        title: qsTr('&Account')
//            Labs.Action { text: qsTr('&Signup') }
        Labs.MenuItem {
            text: 'Account 1'
            group: accounts_group
            checked: true
        }
        Labs.MenuItem {
            text: 'Account 2'
            group: accounts_group
        }
        Labs.MenuSeparator {
        }
        Labs.MenuItem { text: qsTr('&Add Account') }
    }
}
