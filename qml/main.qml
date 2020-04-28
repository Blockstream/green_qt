import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

ApplicationWindow {
    id: window

    property string location: '/'
    property Wallet currentWallet
    property Account currentAccount: currentWallet ? currentWallet.currentAccount : null

    property var icons: ({
        'liquid': '/svg/liquid/liquid_no_string.svg',
        'mainnet': '/svg/btc.svg',
        'testnet': '/svg/btc_testnet.svg'
    })

    property var logos: ({
        'liquid': '/svg/liquid/liquid_with_string.svg',
        'mainnet': '/svg/btc.svg',
        'testnet': '/svg/btc_testnet.svg'
    })

    function formatDateTime(date_time) {
        return new Date(date_time).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
    }

    onCurrentWalletChanged: drawer.close()

    Component.onCompleted: {
        // Auto select wallet if just one wallet
        if (WalletManager.wallets.length === 1) {
            currentWallet = WalletManager.wallets[0];
        }
    }

    width: 1024
    height: 600
    minimumWidth: 800
    minimumHeight: 480
    visible: true
    title: 'Blockstream Green'

    menuBar: MenuBar {
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
                onTriggered: {
                    Qt.openUrlExternally("https://docs.blockstream.com/green/support.html")
                }
            }
        }
    }

    StackView {
        id: stack_view
        anchors.fill: parent
        focus: true

        initialItem: FocusScope {
            StackLayout {
                id: stack_layout
                anchors.fill: parent
                clip: true
                currentIndex: {
                    for (let i = 0; i < WalletManager.wallets.length; i++) {
                        if (WalletManager.wallets[i] === currentWallet) return i + 1;
                    }
                    return 0;
                }
                Intro {
                    focus: stack_layout.currentIndex === 0
                }
                Repeater {
                    model: WalletManager.wallets
                    WalletContainerView {
                        focus: currentWallet === wallet
                        onCanceled2: {
                            currentWallet = null
                        }
                        wallet: modelData
                    }
                }
            }
        }
    }

    DebugActiveFocus {
        visible: false && engine.debug
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
    }

    Action {
        id: create_wallet_action
        text: qsTrId('id_create_new_wallet')
        onTriggered: stack_view.push(signup_view)
    }

    Action {
        id: restore_wallet_action
        text: qsTrId('id_restore_green_wallet')
        onTriggered: stack_view.push(restore_view, { wallet: WalletManager.createWallet() })
    }

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
                icon.source: '/png/ic_home.png'
                icon.color: 'transparent'
                icon.width: 16
                icon.height: 16
            }

            ToolButton {
                onClicked: drawer.close()
                icon.source: '/svg/cancel.svg'
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

    Label {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 4
        font.pixelSize: 10
        opacity: 0.5
        text: `${qsTrId('id_version')} ${Qt.application.version}`
        visible: text.indexOf('-') !== -1
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
}
