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
            navigation.go(`/${wallet.network.id}`)
            self.wallet.disconnect()
        }
    }

    property Action settingsAction: Action {
        enabled: settings_dialog.enabled
        onTriggered: navigation.go(settings_dialog.location)
    }
    DialogLoader {
        id: settings_dialog
        property string location: `${self.location}/settings`
        property bool enabled: !!self.wallet.settings.pricing && !!self.wallet.config.limits
        active: settings_dialog.enabled && navigation.location === settings_dialog.location
        dialog: WalletSettingsDialog {
            parent: window.Overlay.overlay
            wallet: self.wallet
            onRejected: navigation.go(self.location)
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
            Loader {
                active: !wallet.device
                visible: active
                Layout.fillWidth: true
                sourceComponent: EditableLabel {
                    leftPadding: 8
                    rightPadding: 8
                    font.pixelSize: 24
                    font.styleName: 'Medium'
                    text: wallet.name
                    onEdited: {
                        wallet.rename(text, activeFocus)
                    }
                }
            }
            Loader {
                active: wallet.device
                sourceComponent: Label {
                    text: wallet.device.name
                    font.pixelSize: 24
                    font.styleName: 'Medium'
                }
            }
            Loader {
                visible: wallet.device
                sourceComponent: DeviceImage {
                    device: wallet.device
                    sourceSize.height: 32
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (wallet.device.type === Device.BlockstreamJade) {
                                navigation.go(`/jade/${wallet.device.uuid}`)
                            } else if (wallet.device.vendor === Device.Ledger) {
                                navigation.go(`/ledger/${wallet.device.uuid}`)
                            }
                        }
                    }
                }
            }
            HSpacer {
                visible: wallet.device
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
                background: Rectangle {
                    color: 'white'
                    opacity: 0.05
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
                background: Rectangle {
                    color: 'white'
                    opacity: 0.05
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
        focusPolicy: Qt.ClickFocus
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
            focusPolicy: Qt.ClickFocus
            SplitView.fillWidth: true
            SplitView.minimumWidth: self.width / 2
            initialItem: Item {}
            clip: true
        }
    }

    Component {
        id: bump_fee_dialog
        BumpFeeDialog {
        }
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
