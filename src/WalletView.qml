import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import './dialogs'
import './views'

GridLayout {
    property var account: accounts_list.currentItem ? accounts_list.currentItem.account : undefined

    id: wallet_view

    function parseAmount(amount) {
        const unit = wallet.settings.unit;
        return wallet.parseAmount(amount, unit);
    }

    function formatAmount(amount) {
        const include_ticker = true;
        const unit = wallet.settings.unit;
        return wallet.formatAmount(amount || 0, include_ticker, unit);
    }

    function formatFiat(sats) {
        const pricing = wallet.settings.pricing;
        const { fiat, fiat_currency } = wallet.convert(sats);
        return Number(fiat).toLocaleString(Qt.locale(), 'f', 2) + ' ' + fiat_currency;
    }

    function transactionConfirmations(transaction) {
        if (transaction.data.block_height === 0) return 0;
        return 1 + transaction.account.wallet.events.block.block_height - transaction.data.block_height;
    }

    function transactionStatus(transaction) {
        const confirmations = transactionConfirmations(transaction);
        if (confirmations === 0) return qsTr('id_unconfirmed');
        if (!wallet.liquid && confirmations < 6) return qsTr('id_d6_confirmations').arg(confirmations);
        return qsTr('id_completed');
    }

    onAccountChanged: {
        location = '/transactions'
        stack_view.pop()
    }

    rowSpacing: 0
    columnSpacing: 0
    columns: 2

    states: [
        State {
            when: window.location === '/settings'
            name: 'VIEW_SETTINGS'
            PropertyChanges {
                target: title_label
                text: qsTr('id_settings')
            }
            PropertyChanges {
                target: settings_tool_button
                icon.source: 'assets/svg/cancel.svg'
                icon.width: 16
                icon.height: 16
                icon.color: 'transparent'
            }
        }
    ]

    transitions: [
        Transition {
            to: 'VIEW_SETTINGS'
            StackViewPushAction {
                stackView: stack_view
                WalletSettingsView {

                }
            }
        },
        Transition {
            from: 'VIEW_SETTINGS'
            to: ''
            ScriptAction {
                script: stack_view.pop()
            }
        }
    ]

    Action {
        shortcut: 'CTRL+,'
        onTriggered: window.location = '/settings'
    }

    ItemDelegate {
        Layout.preferredWidth: accounts_list.width
        topPadding: 16
        width: parent.width

        onClicked: drawer.open()
        contentItem: RowLayout {
            Image {
                source: icons[wallet.network.id]
                sourceSize.width: 32
                sourceSize.height: 32
            }

            Label {
                text: wallet.name
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            ToolButton {
                text: '⋮'
                onClicked: menu.open()

                Menu {
                    id: menu

                    MenuItem {
                        text: qsTr('id_wallets')
                        onTriggered: drawer.open()
                    }

                    MenuSeparator { }

                    MenuItem {
                        text: qsTr('id_add_new_account')
                        onClicked: create_account_dialog.open()
                    }

                    MenuItem {
                        text: qsTr('id_logout')
                        onTriggered: wallet.disconnect()
                    }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        height: layout.height

        Rectangle {
            z: -1
            color: 'black'
            opacity: 0.2
            anchors.fill: parent
            anchors.bottomMargin: -10000
            anchors.rightMargin: -10000
            anchors.topMargin: -10000
        }

        RowLayout {
            id: layout
            x: 16
            width: parent.width - 32

            Label {
                id: title_label
                font.pixelSize: 16
                text: account.name
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
                height: 1
            }

            ToolButton {
                id: settings_tool_button
                checked: window.location === '/settings'
                checkable: true
                Layout.alignment: Qt.AlignBottom
                icon.source: 'assets/svg/settings.svg'
                icon.width: 24
                icon.height: 24
                onToggled: window.location = checked ? '/settings' : '/transactions'
            }
        }
    }

    AccountListView {
        id: accounts_list
        Layout.fillHeight: true
        Layout.preferredWidth: 320
        clip: true
        topMargin: 1
    }

    StackView {
        id: stack_view
        clip: true
        Layout.fillWidth: true
        Layout.fillHeight: true

        initialItem: Page {
            background: Item { }

            header: RowLayout {
                TabBar {
                    leftPadding: 8
                    background: Item {}
                    id: tab_bar

                    TabButton {
                        text: qsTr('id_transactions')
                        width: 160
                    }

                    TabButton {
                        visible: wallet.network.liquid
                        text: qsTr('id_assets')
                        width: 160
                    }
                }
            }

            StackLayout {
                id: stack_layout
                clip: true
                anchors.fill: parent
                currentIndex: tab_bar.currentIndex

                TransactionListView {
                }

                AssetListView {
                    onClicked: stack_view.push(asset_view_component, { balance })
                }
            }
        }

        Component {
            id: send_dialog
            SendDialog {}
        }

        Component {
            id: receive_dialog
            ReceiveDialog { }
        }
    }

    Component {
        id: transaction_view_component

        TransactionView {

        }
    }

    Component {
        id: asset_view_component
        AssetView {}
    }

    RenameAccountDialog {
        id: rename_account_dialog
    }

    CreateAccountDialog {
        id: create_account_dialog
    }
}
