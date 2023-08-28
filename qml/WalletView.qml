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
import "util.js" as UtilJS

MainPage {
    required property Context context
    required property Wallet wallet
    readonly property Account currentAccount: accounts_list.currentAccount
    readonly property bool fiatRateAvailable: formatFiat(0, false) !== 'n/a'

    Navigation {
        id: navigation
        Component.onCompleted: set({ view: 'transactions' })
    }

    function openCreateDialog() {
        const dialog = create_account_dialog.createObject(window, { wallet: context.wallet })
        dialog.open()
    }

    function parseAmount(account, amount, unit) {
        account.session.displayUnit;
        return wallet.parseAmount(amount, unit || account.session.unit);
    }

    function formatAmount(account, amount, include_ticker = true) {
        if (!account) console.trace()
        account.session.displayUnit;
        const unit = account.session.unit;
        return wallet.formatAmount(amount || 0, include_ticker, unit);
    }

    function formatFiat(sats, include_ticker = true) {
        const ticker = self.currentAccount.session.events.ticker
        const pricing = currentAccount.session.settings.pricing;
        const { fiat, fiat_currency } = wallet.convert({ satoshi: sats });
        const currency = wallet.network.mainnet ? fiat_currency : 'FIAT'
        return (fiat === null ? 'n/a' : Number(fiat).toLocaleString(Qt.locale(), 'f', 2)) + (include_ticker ? ' ' + currency : '');
    }

    function parseFiat(fiat) {
        const ticker = self.currentAccount.session.events.ticker
        fiat = fiat.trim().replace(/,/, '.');
        return fiat === '' ? 0 : wallet.convert({ fiat }).satoshi;
    }

    function transactionConfirmations(transaction) {
        if (transaction.data.block_height === 0) return 0;
        return 1 + transaction.account.session.block.block_height - transaction.data.block_height;
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

    Loader2 {
        active: navigation.param.flow === 'send'
        sourceComponent: SendDialog {
            visible: true
            account: self.currentAccount
            onClosed: {
                navigation.pop()
                destroy()
            }
        }
    }

    Loader2 {
        active: navigation.param.flow === 'receive'
        sourceComponent: ReceiveDialog {
            visible: true
            account: self.currentAccount
            onClosed: {
                navigation.pop()
                destroy()
            }
        }
    }

    Loader2 {
        active: navigation.param.settings ?? false
        property Session session: navigation.param.session ?? null
        sourceComponent: WalletSettingsDialog {
            visible: true
            parent: window.Overlay.overlay
            wallet: self.wallet
            onClosed: {
                navigation.pop()
                destroy()
            }
        }
    }

    id: self
    spacing: 16 //constants.s1
    property alias toolbarItem: wallet_header.toolbarItem

    // unset blur sources, otherwise app crashes on quit
    // TODO: review this workaround while switching to MultiEffect
    Component.onDestruction: {
        header_blur_source.sourceItem = null
        footer_blur_source.sourceItem = null
    }
    ShaderEffectSource {
        id: header_blur_source
        sourceItem: split_view
        sourceRect {
            x: -split_view.x
            y: -split_view.y
            width: self.header.width
            height: self.header.height
        }
    }
    ShaderEffectSource {
        id: footer_blur_source
        sourceItem: split_view
        sourceRect {
            x: -split_view.x
            y: self.footer.y - split_view.y
            width: self.footer.width
            height: self.footer.height
        }
    }

    header: WalletViewHeader {
        id: wallet_header
        context: self.context
        wallet: self.wallet
        currentAccount: self.currentAccount
        accountListWidth: accounts_list.width

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
                opacity: 0.55
                cached: true
                radius: 128
                source: header_blur_source
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
        account: currentAccount
        context: self.context
        wallet: self.wallet

        background: Rectangle {
            color: constants.c600
            FastBlur {
                anchors.fill: parent
                cached: true
                opacity: 0.5
                radius: 64
                source: footer_blur_source
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
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                background: Rectangle {
                    color: 'white'
                    opacity: 0.05
                }
            }
            Label {
                visible: self.currentAccount.session.events?.twofactor_reset?.is_active ?? false
                padding: 8
                leftPadding: 40
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                text: {
                    const data = self.currentAccount.session.events.twofactor_reset
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
        id: split_view
        focusPolicy: Qt.ClickFocus
        handle: Item {
            implicitWidth: constants.p3
            implicitHeight: parent.height
        }

        AccountListView {
            SplitView.preferredWidth: 380
            SplitView.minimumWidth: 200
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
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: constants.p3
        anchors.bottomMargin: constants.p3 * 2
        spacing: 5
        GButton {
            Layout.minimumWidth: 120
            highlighted: true
            visible: !self.context.watchonly
            font.bold: false
            font.weight: 600
            font.pixelSize: 14
            icon.width: 24
            icon.height: 24
            action: Action {
                enabled: UtilJS.effectiveVisible(self) && !self.archived && !self.context.watchonly && !self.wallet.locked && self.currentAccount
                text: qsTrId('id_send')
                icon.source: 'qrc:/svg/send.svg'
                shortcut: 'Ctrl+S'
                onTriggered: {
                    if (self.currentAccount.balance > 0) {
                        onClicked: navigation.set({ flow: 'send' })
                    }
                    else {
                        no_funds_dialog.createObject(window).open()
                    }
                }
            }
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
            ToolTip.visible: hovered && !enabled
        }
        GButton {
            Layout.minimumWidth: 120
            highlighted: true
            enabled: !self.archived && !wallet.locked && self.currentAccount
            font.bold: false
            font.weight: 600
            font.pixelSize: 14
            icon.width: 24
            icon.height: 24
            action: Action {
                enabled: UtilJS.effectiveVisible(self)
                text: qsTrId('id_receive')
                icon.source: 'qrc:/svg/receive.svg'
                shortcut: 'Ctrl+R'
                onTriggered: navigation.set({ flow: 'receive' })
            }
        }
    }

    Component {
        id: bump_fee_dialog
        BumpFeeDialog {
        }
    }

    Component {
        id: no_funds_dialog
        MessageDialog {
            id: dialog
            wallet: self.wallet
            width: 350
            title: qsTrId('id_warning')
            message: self.wallet.network.liquid ? qsTrId('id_insufficient_lbtc_to_send_a') : qsTrId('id_you_have_no_coins_to_send')
            actions: [
                Action {
                    text: qsTrId('id_cancel')
                    onTriggered: dialog.reject()
                },
                Action {
                    property bool highlighted: true
                    text: self.wallet.network.liquid ? qsTrId('id_learn_more') : qsTrId('id_receive')
                    onTriggered: {
                        dialog.reject()
                        if (self.wallet.network.liquid) {
                            Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900000630846-How-do-I-get-Liquid-Bitcoin-L-BTC-')
                        } else {
                            navigation.set({ flow: 'receive' })
                        }
                    }
                }
            ]
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

    Component {
        id: export_transactions_popup
        WalletDialog {
            required property Account account
            wallet: account.context.wallet
            id: dialog
            anchors.centerIn: Overlay.overlay
            showRejectButton: false
            closePolicy: Popup.NoAutoClose
            modal: true
            Overlay.modal: Rectangle {
                color: "#70000000"
            }
            onClosed: dialog.destroy()
            onOpened: controller.save()
            ExportTransactionsController {
                id: controller
                context: dialog.account.context
                account: dialog.account
                onFinished: dialog.accept()
            }
            contentItem: RowLayout {
                BusyIndicator {
                    Layout.alignment: Qt.AlignCenter
                }
            }
        }
    }
}
