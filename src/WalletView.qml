import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import './dialogs'
import './views'

GridLayout {
    id: wallet_view

    property string title: qsTr('id_total_balance') + ': ' + wallet.balance + ' BTC'
    rowSpacing: 10

    property var account: accounts_list.currentItem ? accounts_list.currentItem.account : undefined

    states: State {
        when: window.location === '/settings'
        name: 'VIEW_SETTINGS'
        PropertyChanges {
            target: wallet_view
            title: qsTr('id_settings')
        }
        PropertyChanges {
            target: settings_tool_button
            icon.source: 'assets/svg/arrow_left.svg'
        }
    }

    transitions: [
        Transition {
            to: 'VIEW_SETTINGS'
            StackViewPushAction {
                stackView: stack_view
                WalletSettingsDialog {

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

    columns: 2

    Row {
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        Layout.rightMargin: 10
        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: icons[wallet.network.id]
            width: 28
            height: 28
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 24
            text: wallet.name
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
            anchors.leftMargin: 0
            anchors.bottomMargin: -10000
            anchors.rightMargin: -10000
            anchors.topMargin: -10000
        }

        RowLayout {
            id: layout
            x: 20
            width: parent.width - 40

            Label {
                text: title
                font.pixelSize: 24
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
                    anchors.rightMargin: -5
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
                    font.pixelSize: 16
                    text: account.name
                }

                Label {
                    text: `${account.balance} BTC`
                    font.pixelSize: 20
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

    RenameAccountDialog {
        id: rename_account_dialog
    }

    CreateAccountDialog {
        id: create_account_dialog
    }


    Component {
        id: two_factor_sms_enable_dialog
        EnableSmsTwoFactorDialog {}
    }

    Component {
        id: two_factor_sms_disable_dialog
        TwoFactorSmsDisableDialog {}
    }
}
