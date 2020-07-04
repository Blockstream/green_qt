import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

ApplicationWindow {
    id: window

    property string location: '/'
    readonly property Wallet currentWallet: stack_view.currentItem.wallet || null
    readonly property Account currentAccount: currentWallet ? currentWallet.currentAccount : null

    Component {
        id: container_component
        WalletContainerView {
            onCanceled2: {
                switchToWallet(null)
            }
        }
    }

    property var wallet_views: ({})
    function switchToWallet(wallet) {
        if (wallet) {
            let container = wallet_views[wallet]
            if (!container) {
                container = container_component.createObject(null, { wallet })
                wallet_views[wallet] = container
            }
            stack_view.replace(container)
        } else {
            stack_view.replace(stack_view.initialItem)
        }
        drawer.close()
    }

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

    Component.onCompleted: {
        // Auto select wallet if just one wallet
        if (WalletManager.wallets.length === 1) {
            switchToWallet(WalletManager.wallets[0]);
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
            const account = wallet.currentAccount;
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
        RowLayout {
            children: stack_view.currentItem.toolbar || null
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.alignment: Qt.AlignBottom
        }
    }

    StackView {
        id: stack_view
        anchors.fill: parent
        focus: true
        initialItem: Intro { }
    }

    Action {
        id: create_wallet_action
        text: qsTrId('id_create_new_wallet')
        onTriggered: stack_view.push(signup_view)
    }

    Action {
        id: restore_wallet_action
        text: qsTrId('id_restore_green_wallet')
        onTriggered: stack_view.push(restore_view)
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

        interactive: position > 0
        width: 300
        height: parent.height

        Row {
            anchors.right: parent.right
            anchors.margins: 16
            anchors.top: parent.top
            ToolButton {
                text: '\u2302'
                onClicked: {
                    switchToWallet(currentWallet)
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
          onFinished: stack_view.pop()
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
