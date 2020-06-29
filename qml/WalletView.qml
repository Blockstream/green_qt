import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Item {
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

    property Component toolbar: RowLayout {
        Loader {
            active: currentAccount && currentAccount.json.type === '2of2_no_recovery'
            sourceComponent: AccountIdBadge {
                account: currentAccount
            }
        }
        ToolButton {
            visible: (wallet.events && !!wallet.events.twofactor_reset && wallet.events.twofactor_reset.is_active) || !fiatRateAvailable
            icon.source: 'qrc:/svg/notifications_2.svg'
            icon.color: 'transparent'
            icon.width: 24
            icon.height: 24
            onClicked: notifications_drawer.open()
        }
        ToolButton {
            id: settings_tool_button
            checked: window.location === '/settings'
            checkable: true
            //Layout.alignment: Qt.AlignBottom
            icon.source: 'qrc:/svg/settings.svg'
            icon.width: 24
            icon.height: 24
            onToggled: window.location = checked ? '/settings' : '/transactions'
        }
    }

    Connections {
        target: currentWallet
        function onCurrentAccountChanged() {
            location = '/transactions'
            stack_view.pop()
        }
    }

    states: [
        State {
            when: window.location === '/settings'
            name: 'VIEW_SETTINGS'
            PropertyChanges {
                target: settings_tool_button
                icon.source: 'qrc:/svg/cancel.svg'
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
        parent: stack_view
        anchors.fill: parent
        anchors.leftMargin: -4
        color: 'black'
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
        interactive: position > 0
        height: parent.height
        width: 320
        edge: Qt.RightEdge
        Overlay.modal: Rectangle {
            color: "#70000000"
        }
        ColumnLayout {
            width: 320
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
                    source: 'qrc:/svg/twofactor.svg'
                }
                Rectangle {
                    anchors.fill: parent
                    color: 'white'
                    opacity: 0.05
                    z: -1
                }
            }
        }
    }


    SplitView {
        anchors.fill: parent
        handle: Item {
            implicitWidth: 4
            implicitHeight: 4
        }
        ColumnLayout {
            SplitView.minimumWidth: Math.max(implicitWidth, 300)
            RowLayout {
                Layout.margins: 8
                Layout.leftMargin: 16
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
            }
            AccountListView {
                id: accounts_list
                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true
            }
        }
        StackView {
            SplitView.fillWidth: true
            SplitView.minimumWidth: wallet_view.width / 2
                id: stack_view
                clip: true

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
                            active: !!currentAccount
                            sourceComponent: TransactionListView {
                                account: currentAccount
                            }
                        }

                        Loader {
                            active: !!currentAccount
                            sourceComponent: AssetListView {
                                account: currentAccount
                                onClicked: stack_view.push(asset_view_component, { balance })
                            }
                        }
                    }
                }
        }
    }

    Component {
        id: transaction_view_component
        TransactionView { }
    }
    Component {
        id: asset_view_component
        AssetView { }
    }
    Component {
        id: bump_fee_dialog
        BumpFeeDialog { }
    }
    Component {
        id: send_dialog
        SendDialog { }
    }
    Component {
        id: receive_dialog
        ReceiveDialog { }
    }

    ProgressBar {
        width: parent.width
        height: 2
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
