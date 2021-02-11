import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtQml 2.15

MainPage {
    id: wallet_view

    required property Wallet wallet
    readonly property Account currentAccount: accounts_list.currentAccount

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

    Component {
        id: settings_dialog
        WalletSettingsDialog {
            wallet: wallet_view.wallet
        }
    }

    header: MainPage.Header {
        contentItem: RowLayout {
            spacing: 8

            ColumnLayout {
                RowLayout {
                    Image {
                        sourceSize.height: 16
                        sourceSize.width: 16
                        source: icons[wallet.network.id]
                    }
                    Label {
                        text: wallet.network.name
                        font.pixelSize: 12
                        font.styleName: 'Regular'
                    }
                }
                Label {
                    text: wallet.device ? wallet.device.name : wallet.name
                    font.pixelSize: 32
                    font.styleName: 'Thin'
                }
            }

            DeviceImage {
                visible: wallet.device
                device: wallet.device
                Layout.maximumWidth: 128
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            ProgressBar {
                Layout.maximumWidth: 64
                indeterminate: true
                opacity: wallet.busy ? 0.5 : 0
                visible: opacity > 0
                Behavior on opacity {
                    SmoothedAnimation {
                        duration: 500
                        velocity: -1
                    }
                }
            }
            ToolButton {
                visible: (wallet.events && !!wallet.events.twofactor_reset && wallet.events.twofactor_reset.is_active) || !fiatRateAvailable
                icon.source: 'qrc:/svg/notifications_2.svg'
                icon.color: 'transparent'
                icon.width: 16
                icon.height: 16
                onClicked: notifications_drawer.open()
            }
            ToolButton {
                onClicked: openSettings()
                icon.source: 'qrc:/svg/settings.svg'
                flat: true
                enabled: !!wallet_view.wallet.settings.pricing && !!wallet_view.wallet.config.limits
                ToolTip.text: qsTrId('id_settings')
                ToolTip.delay: 300
                ToolTip.visible: hovered
            }
            ToolButton {
                onClicked: wallet_view.wallet.disconnect()
                icon.source: 'qrc:/svg/logout.svg'
                flat: true
                ToolTip.text: 'Logout'
                ToolTip.delay: 300
                ToolTip.visible: hovered
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
                visible: !fiatRateAvailable
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
                    restoreMode: Binding.RestoreBinding
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


    Component {
        id: account_view_component
        AccountView {}
    }

    property var account_views: ({})
    function switchToAccount(account) {
        if (account) {
            let account_view = account_views[account]
            if (!account_view) {
                account_view = account_view_component.createObject(null, { account })
                account_views[account] = account_view
            }
            if (stack_view.currentItem === account_view) return;
            stack_view.replace(account_view, StackView.Immediate)
        } else {
            stack_view.replace(stack_view.initialItem, StackView.Immediate)
        }
    }

    function openSettings() {
        settings_dialog.createObject(wallet_view).open()
    }

    contentItem: SplitView {
        handle: Item {
            implicitWidth: 16
            implicitHeight: parent.height
        }
        AccountListView {
            id: accounts_list
            Layout.fillHeight: true
            Layout.fillWidth: true
            SplitView.minimumWidth: Math.max(implicitWidth, 300)
            clip: true
            onClicked: switchToAccount(currentAccount)
            onCurrentAccountChanged: switchToAccount(currentAccount)
        }
        StackView {
            id: stack_view
            SplitView.fillWidth: true
            SplitView.minimumWidth: wallet_view.width / 2
            initialItem: Item {}
            clip: true
        }
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

    SystemMessageDialog {
        wallet: wallet_view.wallet
        visible: shouldOpen && wallet_view.match
    }
}
