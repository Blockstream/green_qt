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

    function parseAmount(amount) {
        const unit = wallet.settings.unit
        try {
            amount = Number.fromLocaleString(Qt.locale(), amount)
        } catch (e) {
            amount = Number(amount)
        }

        if (unit === 'BTC') {
            amount = amount * 100000000
        }
        if (unit === 'mBTC') {
            amount = amount * 100000
        }
        if (unit === 'bits' || unit === '\u00B5BTC') {
            amount = amount * 100
        }
        return amount
    }

    function formatAmount(sats) {
        const unit = wallet.settings.unit
        let amount = sats
        let precision = 0
        if (unit === 'BTC') {
            amount = amount / 100000000
            precision = 8
        }
        if (unit === 'mBTC') {
            amount = amount / 100000
            precision = 5
        }
        if (unit === 'bits' || unit === '\u00B5BTC') {
            amount = amount / 100
            precision = 2
        }
        amount = amount.toLocaleString(Qt.locale(), 'f', precision).replace(/[\.,]?0+$/, '')
        return `${amount} ${unit}`
    }

    function convert(sats) {
        wallet.settings.pricing
        const { fiat, fiat_currency } = wallet.convert(sats)
        return `${fiat} ${fiat_currency}`
    }

    property string title: account.name// 'Transactions' //qsTr('id_total_balance') + ': ' + formatAmount(wallet.balance) + ' ' + convert(wallet.balance)
    property var account: accounts_list.currentItem ? accounts_list.currentItem.account : undefined

    rowSpacing: 0
    columns: 2

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

    Row {
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        spacing: 10
        Label {
            id: wallet_balance_label
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 20
            text: formatAmount(wallet.balance)
        }
        Label {
            text: convert(wallet.balance)
            anchors.baseline: wallet_balance_label.baseline
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

            Image {
                source: icons[wallet.network.id]
                sourceSize.width: 32
                sourceSize.height: 32
                Layout.alignment: Qt.AlignVCenter
            }
            Label {
                text: wallet.name
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }
            Image {
                visible: modelData === currentWallet
                sourceSize.width: 16
                sourceSize.height: 16
                source: 'assets/svg/arrow_right.svg'
                Layout.alignment: Qt.AlignVCenter
            }
            Label {
                font.pixelSize: 16
                text: title
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
                        text: convert(account.balance)
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
}
