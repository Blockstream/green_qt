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
        return fiat + ' ' + fiat_currency;
    }

    onAccountChanged: {
        location = '/transactions'
        stack_view.pop()
    }

    rowSpacing: 0
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

    RowLayout {
        Layout.alignment: Qt.AlignRight
        Layout.leftMargin: 30
        Layout.rightMargin: 10
        Layout.bottomMargin: 10
        spacing: 10
        Image {
            source: icons[wallet.network.id]
            sourceSize.width: 32
            sourceSize.height: 32
        }
        Label {
            text: wallet.name
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
        }
        ToolButton {
            text: qsTr('⋮')
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
            onClicked: menu.open()

            Menu {
                id: menu

                MenuItem {
                    text: qsTr('id_wallets')
                    onTriggered: drawer.open()
                }

                MenuItem {
                    enabled: false
                    text: qsTr('id_logout')
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
            anchors.leftMargin: -5
            anchors.bottomMargin: -10000
            anchors.rightMargin: -10000
            anchors.topMargin: -10000
        }

        RowLayout {
            id: layout
            x: 20
            width: parent.width - 40

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

    ListView {
        id: accounts_list
        Layout.fillHeight: true
        Layout.preferredWidth: 300
        clip: true
        spacing: 0
        topMargin: 1
        model: wallet.accounts
        delegate: Pane {
            property bool isCurrentItem: ListView.isCurrentItem
            property Account account: modelData

            padding: 16
            width: ListView.view.width

            background: MouseArea {
                id: mouse_area
                hoverEnabled: true
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
                        width: 2
                        height: parent.height
                    }
                }

            }

            Column {
                spacing: 8
                width: parent.width

                Label {
                    color: isCurrentItem ? 'green' : 'gray'
                    elide: Text.ElideRight
                    font.pixelSize: 16
                    text: account.name
                    width: parent.width
                    ToolTip.text: account.name
                    ToolTip.visible: truncated && mouse_area.containsMouse
                }

                Row {
                    spacing: 10
                    Label {
                        text: formatAmount(account.balance)
                        font.pixelSize: 16
                    }
                    Label {
                        anchors.bottom: parent.bottom
                        text: formatFiat(account.balance)
                    }
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

        initialItem: Page {
            background: Item { }

            header: RowLayout {
                TabBar {
                    padding: 20
                    background: Item {}
                    id: tab_bar

                    TabButton {
                        text: qsTr('id_transactions')
                        width: 120
                    }

                    TabButton {
                        visible: wallet.network.liquid
                        text: qsTr('id_assets')
                        width: 120
                    }
                }
            }

            StackLayout {
                id: stack_layout
                clip: true
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20

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
