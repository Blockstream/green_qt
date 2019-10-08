import Qt.labs.platform 1.1 as Labs
import QtQuick 2.12
import './dialogs'

Labs.MenuBar {
    Labs.Menu {
        title: qsTr('&File')
        Labs.MenuItem {
            text: qsTr('&New Wallet')
            shortcut: StandardKey.New
            onTriggered: create_wallet_action.trigger()
        }
        Labs.MenuItem {
            text: qsTr('&Exit')
            onTriggered: window.close()
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

    Labs.Menu {
        title: qsTr('&Help')

        Labs.MenuItem {
            text: qsTr('&About')
            onTriggered: about_dialog.open()
        }

        Labs.MenuItem {
            text: qsTr('&Support')
            onTriggered: {
                Qt.openUrlExternally("https://docs.blockstream.com/green/support.html")
            }
            shortcut: StandardKey.HelpContents
        }
    }
}
