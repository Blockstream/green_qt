import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import './dialogs'
import './views'

GridLayout {
    columnSpacing: 80
    rowSpacing: 10

    property var account: accounts_list.currentItem ? accounts_list.currentItem.account : undefined

    columns: 2

    Item {
        width: 1
        height: 1
    }

    Item {
        Layout.fillWidth: true
        height: layout.height

        Rectangle {
            z: -1
            color: 'black'
            opacity: 0.2
            anchors.fill: parent
            anchors.leftMargin: -40
            anchors.bottomMargin: -10000
            anchors.rightMargin: -10000
            anchors.topMargin: -10000
        }

        RowLayout {
            id: layout

            width: parent.width

            Row {
                Layout.alignment: Qt.AlignBottom
                padding: 0
                spacing: 8

                Image {
                    source: '../' + icons[wallet.network.id]
                    width: 28
                    height: 28
                    anchors.verticalCenter: total_balance_label.verticalCenter
                }

                Label {
                    id: total_balance_label
                    text: qsTr('id_total_balance') + ':'
                    font.pixelSize: 24
                    font.family: dinpro.name
                }

                Label {
                    text: wallet.balance
                    font.pixelSize: 24
                    font.family: dinpro.name
                }
            }

            Item {
                Layout.fillWidth: true
                height: 1
            }

            ToolButton {
                Rectangle {
                    radius: width/2
                    opacity: 0.05
                    anchors.fill: parent
                }
                Layout.alignment: Qt.AlignBottom
                icon.source: 'assets/svg/settings.svg'
                icon.width: 24
                icon.height: 24

                onClicked: wallet_settings_dialog.open()
            }
        }
    }


    Item {
        width: 1
        height: 1
    }

    RowLayout {
        Layout.minimumHeight: 30

        Label {
            text: qsTr('id_transactions') + (account ? ' - ' + account.name : '')
            font.family: dinpro.name
            font.pixelSize: 14
            font.capitalization: Font.AllUppercase
        }

        Loader {
            visible: stack_view.depth > 1
            sourceComponent: stack_view.currentItem.test
        }
    }

    ListView {
        id: accounts_list
        Layout.fillHeight: true
        Layout.preferredWidth: 300
        spacing: 0
        topMargin: 1
        model: wallet.accounts
        delegate: Pane {
            property bool isCurrentItem: ListView.isCurrentItem
            property Account account: modelData

            padding: 16
            width: ListView.view.width

            background: MouseArea {
                onClicked: accounts_list.currentIndex = index

                Rectangle {
                    z: -2
                    color: Qt.rgba(0, 0, 0, isCurrentItem ? 0.1 : 0)
                    anchors.fill: parent
                    anchors.rightMargin: -40
                    anchors.topMargin: -1

                    Rectangle {
                        visible: isCurrentItem
                        color: 'green'
                        width: 4
                        height: parent.height
                    }
                }

            }

            Column {
                spacing: 8
                width: parent.width

                Label {
                    color: isCurrentItem ? 'green' : 'gray'
                    font.family: dinpro.name
                    font.pixelSize: 16
                    text: account.name
                }


                Label {
                    text: `${account.balance} BTC`
                    font.pixelSize: 20
                    font.family: dinpro.name
                }

                Row {
                    spacing: 8
                    visible: isCurrentItem

                    anchors.right: parent.right
                    FlatButton {
                        icon.source: 'assets/svg/send.svg'
                        icon.width: 24
                        icon.height: 24
                        text: qsTr('id_send')
                        onClicked: send_dialog.createObject(stack_view, { account }).open()
                    }
                    FlatButton {
                        icon.source: 'assets/svg/receive.svg'
                        icon.width: 24
                        icon.height: 24
                        text: qsTr('id_receive')
                        onClicked: receive_dialog.createObject(stack_view).open()
                    }
                }
            }
        }

        ScrollIndicator.vertical: ScrollIndicator { }
    }

    StackView {
        id: stack_view
        clip: true
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.rowSpan: 2

        initialItem: TransactionListView {
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

    Row {
        Layout.alignment: Qt.AlignRight
        FlatButton {
            text: 'ADD ACCOUNT'
            onClicked: create_account_dialog.open()
        }
    }

    Component {
        id: transaction_view_component

        TransactionView {

        }
    }

    WalletSettingsDialog {
        id: wallet_settings_dialog
    }

    RenameAccountDialog {
        id: rename_account_dialog
    }

    CreateAccountDialog {
        id: create_account_dialog
    }
}

