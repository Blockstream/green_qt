import Blockstream.Green.Gui 0.1

MenuBar {
    window: main_window

    Menu {
        title: qsTr('&File')

        Action {
            text: qsTr('id_create_new_wallet')
            onTriggered: create_wallet_action.trigger()
        }
        Action {
            text: qsTr('id_restore_green_wallet')
            onTriggered: restore_wallet_action.trigger()
        }
        Action {
            text: qsTr('&Exit')
            onTriggered: window.close()
        }
    }

    Menu {
        title: qsTr('id_help')

        Action {
            text: qsTr('id_about')
            onTriggered: about_dialog.open()
        }

        Action {
            text: qsTr('id_support')
            onTriggered: {
                Qt.openUrlExternally("https://docs.blockstream.com/green/support.html")
            }
        }
    }
}
