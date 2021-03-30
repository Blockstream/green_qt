import Blockstream.Green.Gui 0.1

MenuBar {
    window: main_window

    Menu {
        title: qsTrId('&File')

        Action {
            text: qsTrId('id_create_new_wallet')
            onTriggered: create_wallet_action.trigger()
        }
        Action {
            text: qsTrId('id_restore_green_wallet')
            onTriggered: restore_wallet_action.trigger()
        }
        Action {
            text: qsTrId('id_wallets')
            onTriggered: drawer.open()
        }
        Action {
            text: qsTrId('&Exit')
            onTriggered: window.close()
        }
    }

    Menu {
        title: qsTrId('id_help')

        Action {
            text: qsTrId('id_about')
            onTriggered: about_dialog.open()
        }

        Action {
            text: qsTrId('id_support')
            onTriggered: Qt.openUrlExternally(constants.supportUrl)
        }
    }
}
