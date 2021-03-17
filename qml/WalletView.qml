import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtQml 2.15

MainPage {
    id: self
    required property Wallet wallet
    readonly property string location: `/${wallet.network.id}/${wallet.id}`
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

    property Action disconnectAction: Action {
        onTriggered: {
            pushLocation(`/${wallet.network.id}`)
            self.wallet.disconnect()
        }
    }

    property Action settingsAction: Action {
        enabled: settings_dialog.enabled
        onTriggered: pushLocation(settings_dialog.location)
    }
    DialogLoader {
        id: settings_dialog
        property string location: `${self.location}/settings`
        property bool enabled: !!self.wallet.settings.pricing && !!self.wallet.config.limits
        active: settings_dialog.enabled && window.location === settings_dialog.location
        dialog: WalletSettingsDialog {
            parent: window.Overlay.overlay
            wallet: self.wallet
            onRejected: popLocation()
        }
    }
    header: MainPageHeader {
        contentItem: RowLayout {
            spacing: 16
            Image {
                sourceSize.height: 32
                sourceSize.width: 32
                source: icons[wallet.network.id]
            }
            Label {
                text: wallet.device ? wallet.device.name : wallet.name
                font.pixelSize: 24
                font.styleName: 'Medium'
            }
            Loader {
                visible: wallet.device
                sourceComponent:  DeviceImage {
                    device: wallet.device
                    sourceSize.height: 32
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (wallet.device.type === Device.BlockstreamJade) {
                                pushLocation(`/jade/${wallet.device.uuid}`)
                            } else if (wallet.device.vendor === Device.Ledger) {
                                pushLocation(`/ledger/${wallet.device.uuid}`)
                            }
                        }
                    }
                }
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
                icon.source: 'qrc:/svg/gearFill.svg'
                flat: true
                action: self.settingsAction
                ToolTip.text: qsTrId('id_settings')
                ToolTip.delay: 300
                ToolTip.visible: hovered
            }
            ToolButton {
                visible: !self.wallet.device
                icon.source: 'qrc:/svg/logout.svg'
                flat: true
                action: self.disconnectAction
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
                text: {
                    const data = wallet.events.twofactor_reset
                    if (!data) return ''
                    if (data.is_disputed) {
                        return qsTrId('id_warning_wallet_locked_by')
                    }
                    if (data.is_active) {
                        console.assert(data.days_remaining > 0)
                        return qsTrId('id_your_wallet_is_locked_for_a').arg(data.days_remaining)
                    }
                    return ''
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

    contentItem: SplitView {
        handle: Item {
            implicitWidth: 20
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
            SplitView.minimumWidth: self.width / 2
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
        id: system_message_dialog
        property bool alreadyOpened: false
        wallet: self.wallet
        visible: shouldOpen && !alreadyOpened && self.match
        onVisibleChanged: {
            if (!visible) {
                Qt.callLater(function () { system_message_dialog.alreadyOpened = true })
            }
        }
    }
}
