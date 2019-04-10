import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import ".."

Dialog {
    anchors.centerIn: Overlay.overlay
    modal: true
    parent: Overlay.overlay
    standardButtons: Dialog.Ok | Dialog.Cancel
    title: qsTr('RENAME ACCOUNT')

    ScrollView {
        id: scroll_view
        anchors.fill: parent
        clip: true

        Column {
            padding: 8
            spacing: 16
            width: parent.width - 16

            Panel {
                title: qsTr('NETWORK')
                icon: 'assets/assets/svg/network.svg'
                width: scroll_view.width - 16
            }
/*
            Panel {
                title: qsTr('ACCOUNT')
                icon: 'assets/assets/svg/account.svg'
                width: scroll_view.width
            }

            Panel {
                title: qsTr('TWO FACTOR')
                icon: 'assets/assets/svg/twofactor.svg'
                width: scroll_view.width
            }
            */

            WalletSecuritySettingsView {
                width: scroll_view.width - 16
            }

            Panel {
                width: scroll_view.width - 16
                title : qsTr('ADVANCED')
                icon: 'assets/assets/svg/advanced.svg'
            }
        }

        // NETWORK
            // PIN
            // WATCH ONLY LOGIN
            // LOGOUT
            // SWITCH NET ?


        // ACCOUNT
            // DENOMINATION
            // REFERENCE EXCHANGE RATE
            // DEFAULT TRANSACTION PRIORITY
            // DEFAULT CUSTOM FEE RATE


        // TWO FACTOR
            // TWO FACTOR AUTHENTUCATION SETUP

        // SECURITY
            // MNEMONIC
            // AUTO LOGOUT TIMEOUT

        //
    }
}
