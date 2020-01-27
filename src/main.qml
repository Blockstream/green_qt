import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12
import './dialogs'

Item {
    property var icons: ({
        'liquid': 'assets/svg/liquid/liquid_no_string.svg',
        'mainnet': 'assets/svg/btc.svg',
        'testnet': 'assets/svg/btc_testnet.svg'
    })

    property var logos: ({
        'liquid': 'assets/svg/liquid/liquid_with_string.svg',
        'mainnet': 'assets/svg/btc.svg',
        'testnet': 'assets/svg/btc_testnet.svg'
    })

    function formatDateTime(date_time) {
        return new Date(date_time).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
    }

    Connections {
        target: window
        onCurrentWalletChanged: drawer.close()
    }

    anchors.fill: parent

    Action {
        id: create_wallet_action
        onTriggered: stack_view.push(signup_view)
    }

    Action {
        id: restore_wallet_action
        onTriggered: stack_view.push(restore_view, { wallet: WalletManager.createWallet() })
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

        width: 300
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

    StackView {
        id: stack_view
        anchors.fill: parent

        initialItem: StackLayout {
            id: stack_layout
            clip: true

            Intro { }

            Repeater {
                model: WalletManager.wallets

                WalletContainerView {
                    property bool current: currentWallet === modelData
                    focus: current

                    onCurrentChanged: if (current) stack_layout.currentIndex = index + 1

                    wallet: modelData
                }
            }
        }
    }

    Component {
        id: signup_view
        SignupView { }
    }

    Component {
        id: restore_view
        RestoreWallet {
          cancel.onTriggered: stack_view.pop()
          accept.onTriggered: {
              WalletManager.insertWallet(wallet)
              currentWallet = wallet;
              stack_view.pop()
          }
        }
    }

    Component {
        id: wallet_foo

        WalletContainerView { }
    }

    Component {
        id: device_view_component

        DeviceView { }
    }
}
