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
        'liquid': 'qrc:/svg/liquid/liquid_no_string.svg',
        'mainnet': 'qrc:/svg/btc.svg',
        'testnet': 'qrc:/svg/btc_testnet.svg'
    })

    property var logos: ({
        'liquid': 'qrc:/svg/liquid/liquid_with_string.svg',
        'mainnet': 'qrc:/svg/btc.svg',
        'testnet': 'qrc:/svg/btc_testnet.svg'
    })

    function formatDateTime(date_time) {
        return new Date(date_time).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
    }

    function fitMenuWidth(menu) {
        let result = 0;
        let padding = 0;
        for (let i = 0; i < menu.count; ++i) {
            const item = menu.itemAt(i);
            result = Math.max(item.contentItem.implicitWidth, result);
            padding = Math.max(item.padding, padding);
        }
        return result + padding * 2;
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
    title: {
        const wallet = currentWallet
        const parts = []
        if (wallet) {
            parts.push(wallet.name);
            const account = currentWallet.currentAccount;
            if (account) parts.push(account.name);
        }
        parts.push('Blockstream Green');
        return parts.join(' - ');
    }

    header: RowLayout {
        ToolButton {
            text: '\u2630'
            onClicked: drawer.open()
        }
        MenuBar {
            Menu {
                title: qsTrId('File')
                width: fitMenuWidth(this)
                Action {
                    text: qsTrId('id_create_new_wallet')
                    onTriggered: create_wallet_action.trigger()
                }
                Action {
                    text: qsTrId('id_restore_green_wallet')
                    onTriggered: restore_wallet_action.trigger()
                }
                Menu {
                    title: qsTrId('id_export_transactions_to_csv_file')
                    enabled: currentWallet && currentWallet.authentication === Wallet.Authenticated
                    Repeater {
                        model: currentWallet ? currentWallet.accounts : null
                        MenuItem {
                            text: modelData.name
                            onTriggered: modelData.exportCSV()
                        }
                    }
                }
                Action {
                    text: qsTrId('&Exit')
                    onTriggered: window.close()
                }
            }
            Menu {
                title: qsTrId('Wallet')
                width: fitMenuWidth(this)
                MenuItem {
                    text: qsTrId('id_settings')
                    enabled: currentWallet && currentWallet.authentication === Wallet.Authenticated
                    onClicked: location = '/settings'
                }
                MenuItem {
                    enabled: currentWallet && currentWallet.connection !== Wallet.Disconnected
                    text: qsTrId('id_log_out')
                    onClicked: currentWallet.disconnect()
                }
                MenuSeparator { }
                MenuItem {
                    text: qsTrId('id_add_new_account')
                    onClicked: create_account_dialog.createObject(window).open()
                    enabled: currentWallet && currentWallet.authentication === Wallet.Authenticated
                }
                MenuItem {
                    text: qsTrId('id_rename_account')
                    enabled: currentWallet && currentWallet.authentication === Wallet.Authenticated && currentAccount && currentAccount.json.type !== '2of2_no_recovery'
                    onClicked: rename_account_dialog.createObject(window, { account: currentAccount }).open()
                }
            }
            Menu {
                title: qsTrId('id_help')
                width: fitMenuWidth(this)
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
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        Loader {
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.alignment: Qt.AlignBottom
            sourceComponent: stack_view.currentItem.toolbar
        }
    }

    StackView {
        id: stack_view
        anchors.fill: parent
        focus: true

        initialItem: FocusScope {
            property Component toolbar: stack_layout.children[stack_layout.currentIndex].toolbar
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
                    property Component toolbar: TextField {
                        visible: stack_view.depth === 1 && !currentWallet
                        width: 256
                        onTextChanged: WalletManager.filter = text.trim()
                        placeholderText: qsTrId('id_search')
                    }
                    focus: stack_layout.currentIndex === 0
                }
                Repeater {
                    model: WalletManager.wallets
                    WalletContainerView {
                        Connections {
                            target: modelData
                            onLoginAttemptsRemainingChanged: {
                                if (loginAttemptsRemaining === 0) {
                                    currentWallet = null;
                                }
                            }
                        }

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
                text: '\u2302'
                onClicked: {
                    currentWallet = null
                    drawer.close()
                }
            }

            ToolButton {
                onClicked: drawer.close()
                icon.source: 'qrc:/svg/cancel.svg'
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
        id: rename_account_dialog
        RenameAccountDialog {}
    }

    Component {
        id: create_account_dialog
        CreateAccountDialog {
            wallet: currentWallet
        }
    }
}
