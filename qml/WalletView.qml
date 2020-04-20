import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Item {
    property Account currentAccount
    readonly property Account account: currentAccount || wallet.accounts[0] || null

    id: wallet_view

    function parseAmount(amount) {
        const unit = wallet.settings.unit;
        return wallet.parseAmount(amount, unit);
    }

    function formatAmount(amount, include_ticker = true) {
        const unit = wallet.settings.unit;
        return wallet.formatAmount(amount || 0, include_ticker, unit);
    }

    function formatFiat(sats, include_ticker = true) {
        const pricing = wallet.settings.pricing;
        const { fiat, fiat_currency } = wallet.convert({ satoshi: sats });
        return (fiat === null ? 'n/a' : Number(fiat).toLocaleString(Qt.locale(), 'f', 2)) + (include_ticker ? ' ' + fiat_currency : '');
    }

    function parseFiat(fiat) {
        fiat = fiat.trim().replace(/,/, '.');
        return fiat === '' ? 0 : wallet.convert({ fiat }).satoshi;
    }

    function transactionConfirmations(transaction) {
        if (transaction.data.block_height === 0) return 0;
        return 1 + transaction.account.wallet.events.block.block_height - transaction.data.block_height;
    }

    function transactionStatus(confirmations) {
        if (confirmations === 0) return qsTrId('id_unconfirmed');
        if (!wallet.network.liquid && confirmations < 6) return qsTrId('id_d6_confirmations').arg(confirmations);
        return qsTrId('id_completed');
    }

    readonly property bool fiatRateAvailable: formatFiat(0, false) !== 'n/a'

    onAccountChanged: {
        location = '/transactions'
        stack_view.pop()
    }

    states: [
        State {
            when: window.location === '/settings'
            name: 'VIEW_SETTINGS'
            PropertyChanges {
                target: title_label
                text: qsTrId('id_settings')
            }
            PropertyChanges {
                target: settings_tool_button
                icon.source: '/svg/cancel.svg'
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

    Rectangle {
        x: account_header.x
        y: 0
        color: 'black'
        width: parent.width - x
        height: parent.height
        opacity: 0.1

        Rectangle {
            width: parent.height
            height: 32
            x: 32
            opacity: 1
            transformOrigin: Item.TopLeft
            rotation: 90
            gradient: Gradient {
                GradientStop { position: 1.0; color: '#ff000000' }
                GradientStop { position: 0.0; color: '#00000000' }
            }
        }
    }

    Drawer {
        id: notifications_drawer
        height: parent.height
        width: 320
        edge: Qt.RightEdge
        Overlay.modal: Rectangle {
            color: "#70000000"
        }
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            Label {
                visible: fiatRateAvailable
                text: qsTrId('id_your_favourite_exchange_rate_is')
                padding: 8
                leftPadding: 40
                wrapMode: Label.WordWrap
                Layout.fillWidth: true
                Rectangle {
                    anchors.fill: parent
                    color: 'white'
                    opacity: 0.05
                    z: -1
                }
            }
            Label {
                visible: wallet.events && !!wallet.events.twofactor_reset && wallet.events.twofactor_reset.is_active
                padding: 8
                leftPadding: 40
                wrapMode: Label.WordWrap
                Layout.fillWidth: true
                Binding on text {
                    when: !!wallet.events.twofactor_reset
                    value: qsTrId('id_your_wallet_is_locked_for_a').arg(wallet.events.twofactor_reset ? wallet.events.twofactor_reset.days_remaining : 0)
                }
                Image {
                    y: 8
                    x: 8
                    source: '/svg/twofactor.svg'
                }
                Rectangle {
                    anchors.fill: parent
                    color: 'white'
                    opacity: 0.05
                    z: -1
                }
            }
            Item {
                Layout.fillHeight: true
                width: 1
            }
        }
    }

    GridLayout {
        anchors.fill: parent
        rowSpacing: 0
        columnSpacing: 0
        columns: 2

        ItemDelegate {
            id: account_title
            Layout.preferredWidth: accounts_list.width
            width: parent.width

            onClicked: drawer.open()
            contentItem: RowLayout {
                Item {
                    clip: true
                    implicitWidth: account_title.hovered ? 32 : 0
                    implicitHeight: 32
                    Behavior on implicitWidth { SmoothedAnimation {} }
                    ToolButton {
                        enabled: false
                        anchors.centerIn: parent
                        icon.source:'/svg/arrow_left.svg'
                        icon.width: 16
                        icon.height: 16
                        icon.color: 'white'
                    }
                }

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
                            text: qsTrId('id_wallets')
                            onTriggered: drawer.open()
                        }

                        MenuSeparator { }

                        MenuItem {
                            text: qsTrId('id_add_new_account')
                            onClicked: create_account_dialog.createObject(wallet_view).open()
                        }
                        MenuItem {
                            text: qsTrId('id_rename_account')
                            enabled: account && account.json.type !== '2of2_no_recovery'
                            onClicked: rename_account_dialog.createObject(wallet_view, { account }).open()
                        }
                        MenuItem {
                            text: qsTrId('id_log_out')
                            onTriggered: wallet.disconnect()
                        }
                    }
                }
            }
        }

        Item {
            id: account_header
            Layout.fillWidth: true
            height: layout.height

            RowLayout {
                id: layout
                x: 16
                width: parent.width - 32

                Label {
                    id: title_label
                    font.pixelSize: 16
                    text: account ? account.name : ''
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    height: 1
                }
                Loader {
                    active: account && account.json.type === '2of2_no_recovery'
                    sourceComponent: AccountIdBadge { }
                }
                ToolButton {
                    visible: (wallet.events && !!wallet.events.twofactor_reset && wallet.events.twofactor_reset.is_active) || !fiatRateAvailable
                    Layout.alignment: Qt.AlignBottom
                    icon.source: '/svg/notifications_2.svg'
                    icon.color: 'transparent'
                    icon.width: 24
                    icon.height: 24
                    onClicked: notifications_drawer.open()
                }

                ToolButton {
                    id: settings_tool_button
                    checked: window.location === '/settings'
                    checkable: true
                    Layout.alignment: Qt.AlignBottom
                    icon.source: '/svg/settings.svg'
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
                        leftPadding: 16
                        background: Item {}
                        id: tab_bar

                        TabButton {
                            text: qsTrId('id_transactions')
                            width: 160
                        }

                        TabButton {
                            visible: wallet.network.liquid
                            text: qsTrId('id_assets')
                            width: 160
                        }
                    }
                }

                StackLayout {
                    id: stack_layout
                    clip: true
                    anchors.fill: parent
                    currentIndex: tab_bar.currentIndex

                    Loader {
                        active: !!account
                        sourceComponent: TransactionListView {}
                    }

                    Loader {
                        active: !!account
                        sourceComponent: AssetListView {
                            onClicked: stack_view.push(asset_view_component, { balance })
                        }
                    }
                }
            }

            Component {
                id: send_dialog
                SendDialog { }
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

        Component {
            id: rename_account_dialog
            RenameAccountDialog {}
        }

        Component {
            id: create_account_dialog
            CreateAccountDialog {}
        }
        Component {
            id: bump_fee_dialog
            BumpFeeDialog { }
        }
    }

    ProgressBar {
        width: parent.width
        indeterminate: true
        opacity: wallet.busy ? 0.5 : 0
        Behavior on opacity {
            SmoothedAnimation {
                duration: 500
                velocity: -1
            }
        }
    }
}
