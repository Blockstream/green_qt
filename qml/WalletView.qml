import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQml
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS

MainPage {
    required property Context context
    required property Wallet wallet
    readonly property Account currentAccount: accounts_list.currentAccount
    readonly property bool fiatRateAvailable: formatFiat(0, false) !== 'n/a'

    Navigation {
        id: navigation
        Component.onCompleted: set({ view: wallet.network.liquid ? 'overview' : 'transactions' })
    }

    function openCreateDialog() {
        const dialog = create_account_dialog.createObject(window, { wallet: context.wallet })
        dialog.open()
    }

    function parseAmount(amount, unit) {
        wallet.context.displayUnit;
        return wallet.parseAmount(amount, unit || wallet.context.settings.unit);
    }

    function formatAmount(amount, include_ticker = true) {
        wallet.context.displayUnit;
        const unit = wallet.context.settings.unit;
        return wallet.formatAmount(amount || 0, include_ticker, unit);
    }

    function formatFiat(sats, include_ticker = true) {
        const ticker = wallet.context.events.ticker
        const pricing = wallet.context.settings.pricing;
        const { fiat, fiat_currency } = wallet.convert({ satoshi: sats });
        const currency = wallet.network.mainnet ? fiat_currency : 'FIAT'
        return (fiat === null ? 'n/a' : Number(fiat).toLocaleString(Qt.locale(), 'f', 2)) + (include_ticker ? ' ' + currency : '');
    }

    function parseFiat(fiat) {
        const ticker = wallet.context.events.ticker
        fiat = fiat.trim().replace(/,/, '.');
        return fiat === '' ? 0 : wallet.convert({ fiat }).satoshi;
    }

    function transactionConfirmations(transaction) {
        if (transaction.data.block_height === 0) return 0;
        return 1 + transaction.account.context.session.block.block_height - transaction.data.block_height;
    }

    function transactionStatus(confirmations) {
        if (confirmations === 0) return qsTrId('id_unconfirmed');
        if (!wallet.network.liquid && confirmations < 6) return qsTrId('id_d6_confirmations').arg(confirmations);
        return qsTrId('id_completed');
    }

    function localizedLabel(label) {
        switch (label) {
            case '':
            case 'all':
                return qsTrId('id_all')
            case 'csv':
                return qsTrId('id_csv')
            case 'p2wsh':
                return qsTrId('id_p2wsh')
            case 'p2sh':
                return qsTrId('id_p2sh')
            case 'not_confidential':
                return qsTrId('id_not_confidential')
            case 'dust':
                return qsTrId('id_dust')
            case 'locked':
                return qsTrId('id_locked')
            case 'expired':
                return qsTrId('id_2fa_expired')
            case 'p2wpkh':
                return 'p2wpkh'
            case 'p2sh-p2wpkh':
                return 'p2sh-p2wpkh'
            default:
                console.warn(`missing localized label for ${label}`)
                console.trace()
                return label
        }
    }

    readonly property bool ready: {
        const accounts = self.wallet?.context.accounts ?? null
        if (!accounts || accounts.length === 0) return false
        for (let i = 0; i < accounts.length; i++) {
            if (!accounts[i].ready) return false
        }
        return true
    }

    // TODO
    onReadyChanged: if (ready) Analytics.recordEvent('wallet_active', AnalyticsJS.segmentationWalletActive(self.wallet))

    AnalyticsAlert {
        id: overview_alert
        screen: 'Overview'
        network: self.wallet.network.id
    }

    AccountListModel {
        id: account_list_model
        context: self.context
        filter: '!hidden'
    }

    AccountListModel {
        id: archive_list_model
        context: self.context
        filter: 'hidden'
    }

    Controller {
        id: controller
        context: self.context
    }

    FeeEstimates {
        id: fee_estimates
        context: self.context
    }

    Loader2 {
        active: navigation.param.settings ?? false
        sourceComponent: WalletSettingsDialog {
            visible: true
            parent: window.Overlay.overlay
            wallet: self.wallet
            onRejected: navigation.pop()
            onClosed: destroy()
        }
    }
    id: self
    spacing: constants.s1
    header: WalletViewHeader {
        context: self.context
        wallet: self.wallet
        currentAccount: self.currentAccount
        toobar: stack_view.currentItem?.toolbar ?? null

        background: Rectangle {
            color: constants.c700
            opacity: Math.max(stack_view.currentItem?.contentY ?? 0, accounts_list.contentY) > 0 ? 1 : 0
            Behavior on opacity {
                SmoothedAnimation {
                    velocity: 4
                }
            }

            FastBlur {
                anchors.fill: parent
                cached: true
                opacity: 0.55

                radius: 128
                source: ShaderEffectSource {
                    sourceItem: self.contentItem
                    sourceRect {
                        x: -self.contentItem.x
                        y: -self.contentItem.y
                        width: self.header.width
                        height: self.header.height
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                y: parent.height - 1
                color: constants.c900
            }
        }
    }
    footer: WalletViewFooter {
        context: self.context
        wallet: self.wallet

        background: Rectangle {
            color: constants.c600
            FastBlur {
                anchors.fill: parent
                cached: true
                opacity: 0.5
                radius: 64
                source: ShaderEffectSource {
                    sourceItem: self.contentItem
                    sourceRect {
                        x: -self.contentItem.x
                        y: self.footer.y - self.contentItem.y
                        width: self.footer.width
                        height: self.footer.height
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: constants.c900
                opacity: 0.5
            }
            Rectangle {
                width: parent.width
                height: 1
                y: 1
                color: constants.c200
                opacity: 0.5
            }
        }
    }

    Drawer {
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
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                background: Rectangle {
                    color: 'white'
                    opacity: 0.05
                }
            }
            Label {
                visible: wallet.context.events?.twofactor_reset?.is_active ?? false
                padding: 8
                leftPadding: 40
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                text: {
                    const data = wallet.context.events.twofactor_reset
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
        AccountView {
        }
    }

    property var account_views: ({})
    function switchToAccount(account) {
        if (account) {
            const context = self.context
            let account_view = account_views[account]
            if (!account_view) {
                account_view = account_view_component.createObject(null, { context, account })
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
            implicitWidth: constants.p3
            implicitHeight: parent.height
        }

        AccountListView {
            SplitView.preferredWidth: 380
            SplitView.minimumWidth: 300
            SplitView.maximumWidth: self.width / 3
            id: accounts_list
            context: self.wallet.context
            onCurrentAccountChanged: switchToAccount(currentAccount)
        }

        StackView {
            SplitView.fillWidth: true
            SplitView.minimumWidth: self.width / 2
            id: stack_view
            initialItem: Item {}
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
        visible: shouldOpen && !alreadyOpened
        onVisibleChanged: {
            if (!visible) {
                Qt.callLater(function () { system_message_dialog.alreadyOpened = true })
            }
        }
    }
}
