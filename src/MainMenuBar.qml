import Blockstream.Green.Gui 0.1

MenuBar {
    window: main_window

    Menu {
        title: qsTr('&File')

        Action {
            text: qsTr('&New Wallet')
            onTriggered: create_wallet_action.trigger()
        }
        Action {
            text: qsTr('&Restore Wallet')
            onTriggered: restore_wallet_action.trigger()
        }
        Action {
            text: qsTr('&Exit')
            onTriggered: window.close()
        }
    }

    Menu {
        title: qsTr('&Help')

        Action {
            text: qsTr('&About')
            onTriggered: about_dialog.open()
        }

        Action {
            text: qsTr('&Support')
            onTriggered: {
                Qt.openUrlExternally("https://docs.blockstream.com/green/support.html")
            }
        }
    }
}
