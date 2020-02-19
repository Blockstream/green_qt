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
        text: qsTr('id_create_new_wallet')
        onTriggered: stack_view.push(signup_view)
    }

    Action {
        id: restore_wallet_action
        text: qsTrId('id_restore_wallet')
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

        Row {
            anchors.right: parent.right
            anchors.margins: 16
            anchors.top: parent.top
            ToolButton {
                onClicked: {
                    currentWallet = null
                    drawer.close()
                }
                icon.source: 'assets/png/ic_home.png'
                icon.color: 'transparent'
                icon.width: 16
                icon.height: 16
            }

            ToolButton {
                onClicked: drawer.close()
                icon.source: 'assets/svg/cancel.svg'
                icon.width: 16
                icon.height: 16
            }
        }

        Sidebar {
            id: sidebar
            anchors.fill: parent
            anchors.topMargin: 64
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

            currentIndex: {
                for (let i = 0; i < WalletManager.wallets.length; i++) {
                    if (WalletManager.wallets[i] === currentWallet) return i + 1;
                }
                return 0;
            }

            Intro { }

            Repeater {
                model: WalletManager.wallets

                WalletContainerView {
                    onCanceled2: {
                        currentWallet = null
                    }
                    wallet: modelData
                }
            }
        }
    }

    Component {
        id: signup_view
        SignupView {
            onClose: stack_view.pop()
        }
    }

    Component {
        id: restore_view
        RestoreWallet {
          onCanceled2: stack_view.pop()
          onFinished: {
              WalletManager.insertWallet(wallet)
              currentWallet = wallet;
              stack_view.pop()
          }
        }
    }

    Component {
        id: device_view_component

        DeviceView { }
    }
}
