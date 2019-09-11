import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import './dialogs'
import './views'

Page {
    id: self

    property var account: xpto.currentItem < 0 ? null : wallet.accounts[xpto.currentIndex]

    Drawer {
        id: drawer
        edge: Qt.RightEdge
        //parent: ApplicationWindow.window
        width: 200
        height: parent.height
        Text {
            anchors.fill: parent
            text: JSON.stringify(wallet.events)
        }
    }

    footer: Pane {
        background: Rectangle {
            color: 'white'
            opacity: 0.15
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 0

            AmountConverter {
                id: converter
                wallet: account ? account.wallet : null
                input: ({ btc: account ? account.json.balance.btc.btc : 0 })
            }

            Amount {
                Layout.alignment: Qt.AlignRight
                amount: account ? account.json.balance.btc.btc : 0
                pixelSize: 16
                currency: 'BTC'
                currencyBorder: false
            }

            Amount {
                Layout.alignment: Qt.AlignRight
                amount: converter.valid ? converter.output.fiat : 0
                currency: converter.valid ? converter.output.fiat_currency : ''
                pixelSize: 16
                currencyBorder: false
            }


            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 64
            }


            FlatButton {
                icon.source: 'assets/assets/svg/send.svg'
                icon.width: 16
                icon.height: 16
                text: qsTr('SEND')

                onClicked: {
                    tab_bar.currentIndex = 2
                }
            }
        }
    }

    header: Pane {
        bottomPadding: 0
        topPadding: 0

        background: Rectangle {
            color: 'black'
            opacity: 0.15
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 0

            Image {
                source: 'assets/assets/svg/btc_testnet.svg'
                sourceSize.width: 32
                sourceSize.height: 32
            }

            Label {
                text: wallet.name
            }

            Image {
                source: 'assets/assets/svg/arrow_right.svg'
                sourceSize.width: 16
                sourceSize.height: 16
            }

            ComboBox {
                id: xpto
                model: wallet.accounts
                Layout.fillWidth: true
                //textRole: 'name'
                displayText: `${account.name}   [${account.json.type}]`
                flat: true
                delegate: ItemDelegate {
                    property Account account: modelData
                    text: account.name
                    width: parent.width
                    highlighted: ListView.isCurrentItem
                }
            }

            Menu {
                id: foo_menu

                MenuItem {
                    text: qsTr('NEW ACCOUNT')

                    onClicked: create_account_dialog.open()
                }

                MenuSeparator {}

                MenuItem {
                    text: qsTr(`RENAME ${account.name}`)
                    enabled: !account.mainAccount
                    onClicked: rename_account_dialog.open()
                }
            }

            ToolButton {
                icon.source: 'assets/assets/svg/stack_wallets.svg'
                icon.width: 16
                icon.height: 16

                onClicked: foo_menu.popup()
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 64
            }

            BusyIndicator {
                visible: false
                running: true
                scale: 0.25
            }

            ToolButton {
                icon.source: 'assets/assets/svg/settings.svg'
                icon.width: 16
                icon.height: 16

                onClicked: wallet_settings_dialog.open()
            }

            ToolButton {
                icon.source: 'assets/assets/svg/notifications.svg'
                icon.width: 16
                icon.height: 16
                onClicked: drawer.open()
            }
        }
    }

    StackView {
        id: stack_view

        anchors.fill: parent

        initialItem: Page {

            header: TabBar {
                id: tab_bar

                background: Rectangle {
                    color: 'black'
                    opacity: 0.1
                }

                currentIndex: 1

                TabButton {
                    text: qsTr('OVERVIEW')
                }

                TabButton {
                    text: qsTr('TRANSACTIONS')
                }

                TabButton {
                    text: qsTr('SEND')
                    icon.source: 'assets/assets/svg/send.svg'
                    icon.width: 16
                    icon.height: 16
                }
                TabButton {
                    text: qsTr('RECEIVE')
                    icon.source: 'assets/assets/svg/receive.svg'
                    icon.width: 16
                    icon.height: 16
                }
            }

            StackLayout {
                anchors.fill: parent

                clip: true

                currentIndex: tab_bar.currentIndex

                OverviewView {

                }

                TransactionListView {

                }

                SendView {
                    Layout.margins: 8
                }

                ReceiveView {
                    Layout.margins: 8
                }
            }
        }
    }

    Component {
        id: transaction_view_component
        TransactionView {

        }
    }

    CreateAccountDialog {
        id: create_account_dialog
    }

    RenameAccountDialog {
        id: rename_account_dialog
    }

    WalletSettingsDialog {
        id: wallet_settings_dialog
    }
}

