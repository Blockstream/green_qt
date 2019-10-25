import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12
import './dialogs'

Item {
    id: split_view

    property Wallet currentWallet

    onCurrentWalletChanged: drawer.close()

    anchors.fill: parent

    Action {
        id: create_wallet_action
        onTriggered: stack_view.currentIndex = 1
    }

    Action {
        id: restore_wallet_action
        onTriggered: stack_view.currentIndex = 2
    }

    MainMenuBar { }

    AboutDialog {
        id: about_dialog
    }

    Drawer {
        id: drawer
        Action {
            shortcut: 'CTRL+I'
            onTriggered: drawer.open()
        }

        width: 200
        height: parent.height

        Sidebar {
            id: sidebar
            anchors.fill: parent
            anchors.topMargin: 50
        }

        Overlay.modal: Rectangle {
            color: "#70000000"
        }
    }

    StackLayout {
        id: stack_view
        anchors.fill: parent
        clip: true

        Intro { }

        SignupView { }

        RestoreWallet {

        }

        Repeater {
            model: WalletManager.wallets

            WalletFoo {
                property bool current: currentWallet === modelData
                focus: current

                onCurrentChanged: if (current) stack_view.currentIndex = index + 3

                wallet: modelData
            }
        }
    }

    Component {
        id: wallet_foo

        WalletFoo { }
    }

    Component {
        id: device_view_component

        DeviceView { }
    }
}
