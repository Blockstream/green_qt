import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal logout()

    required property Context context
    readonly property Wallet wallet: self.context.wallet
    readonly property Account currentAccount: accounts_list.currentAccount
    readonly property bool fiatRateAvailable: formatFiat(0, false) !== 'n/a'

    Connections {
        target: self.context
        function onAutoLogout() {
            self.logout()
        }
    }

    Navigation {
        id: navigation
        Component.onCompleted: set({ view: 'transactions' })
    }

    function openCreateAccountDrawer({ dismissable = true } = {}) {
        const network = self.currentAccount?.network ?? NetworkManager.networkForDeployment(self.context.deployment)
        const id = network.liquid ? network.policyAsset : network.key
        const asset = self.context.getOrCreateAsset(id)
        create_account_drawer.createObject(self, { context: self.context, asset, dismissable }).open()
    }

    function parseAmount(account, amount, unit) {
        account.session.displayUnit;
        return wallet.parseAmount(amount, unit || account.session.unit);
    }

    function formatAmount(account, amount, include_ticker = true) {
        if (!account) return '-'
        account.session.displayUnit;
        const unit = account.session.unit;
        return wallet.formatAmount(amount || 0, include_ticker, unit);
    }

    function formatFiat(sats, include_ticker = true) {
        if (!self.currentAccount) return '-'
        const ticker = self.currentAccount.session.events.ticker
        const pricing = currentAccount.session.settings.pricing;
        const { fiat, fiat_currency } = wallet.convert({ satoshi: sats });
        const currency = self.deployment === 'mainnet' ? fiat_currency : 'FIAT'
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

    readonly property bool ready: true

    /* TODO: handle ready and wallet_active events
        const accounts = self.wallet?.context.accounts ?? null
        if (!accounts || accounts.length === 0) return false
        for (let i = 0; i < accounts.length; i++) {
            if (!accounts[i].ready) return false
        }
        return true
    }

    // TODO
    onReadyChanged: if (ready) Analytics.recordEvent('wallet_active', AnalyticsJS.segmentationWalletActive(self.wallet))

    LoginDialog {
        wallet: self.wallet
        visible: self.visible && !self.wallet.context
        //onRejected: navigation.pop()
        //onAccepted: navigation.push({ wallet: wallet.id })
        //onClosed: destroy()
    }
    */

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

    Component.onCompleted: {
        let relevant = 0
        for (let i = 0; i < self.context.accounts.length; i++) {
            const account = self.context.accounts[i]
            if (account.network.electrum) {
                if (account.pointer > 0 || account.json.bip44_discovered) {
                    relevant ++
                }
            } else {
                relevant ++
            }
        }
        if (relevant === 0) {
            fresh_wallet_dialog.createObject(Overlay.overlay).open()
        }
    }

    Component {
        id: fresh_wallet_dialog
        FreshWalletDialog {
            onAccepted: openCreateAccountDrawer({ dismissable: false })
        }
    }

    id: self
    title: self.wallet.name
    spacing: 16
    property alias toolbarItem: wallet_header.toolbarItem

    header: WalletViewHeader {
        onAssetsClicked: assets_drawer.createObject(self, { context: self.context }).open()
        onLogoutClicked: self.logout()
        onArchivedAccountsClicked: archived_accounts_dialog.open()

        id: wallet_header
        context: self.context
        wallet: self.wallet
        currentAccount: self.currentAccount
        accountListWidth: accounts_list.width
    }
    footer: Item {
        implicitHeight: 16
    }

    Component {
        id: create_account_drawer
        CreateAccountDrawer {
            onCreated: (account) => switchToAccount(account)
        }
    }

    Component {
        id: receive_drawer
        ReceiveDrawer {
        }
    }

    Component {
        id: transaction_details_drawer
        TransactionDetailsDrawer {
        }
    }

    Component {
        id: address_details_drawer
        AddressDetailsDrawer {
        }
    }

    Component {
        id: send_drawer
        SendDrawer {
        }
    }

    Component {
        id: assets_drawer
        AssetsDrawer {
        }
    }

    ArchivedAccountsDialog {
        id: archived_accounts_dialog
        context: self.context
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
            onTransactionClicked: (transaction) => transaction_details_drawer.createObject(self, { context: self.context, transaction }).open()
            onAddressClicked: (address) => address_details_drawer.createObject(self, { context: self.context, address }).open()
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

        Page {
            SplitView.preferredWidth: 380
            SplitView.minimumWidth: 200
            SplitView.maximumWidth: self.width / 3
            id: side_view
            padding: 0
            background: null
            contentItem: AccountListView {
                id: accounts_list
                context: self.wallet.context
                onCurrentAccountChanged: switchToAccount(currentAccount)
            }
            footer: ColumnLayout {
                spacing: 0
                Hint1Pane {
                    Layout.fillWidth: true
                    id: hint1_page
                    visible: (side_view.height - accounts_list.contentHeight) > hint1_page.height
                }
                Hint2Pane {
                    Layout.fillWidth: true
                    id: hint2_page
                    visible: (side_view.height - accounts_list.contentHeight) > (hint1_page.height + 10 + hint2_page.height)
                }
            }
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
        PrimaryButton {
            Layout.minimumWidth: 120
            icon.source: 'qrc:/svg/send.svg'
            text: qsTrId('id_send')
            action: Action {
                enabled: UtilJS.effectiveVisible(self) && !self.archived && !self.context.watchonly && !self.wallet.locked && self.currentAccount
                shortcut: 'Ctrl+S'
                onTriggered: {
                    const context = self.context
                    const account = self.currentAccount
                    const network = account.network
                    const asset = context.getOrCreateAsset(network.liquid ? network.policyAsset : network.key)
                    const drawer = send_drawer.createObject(self, { context, account, asset })
                    drawer.open()
                }
            }
        }
        PrimaryButton {
            Layout.minimumWidth: 120
            icon.source: 'qrc:/svg/receive.svg'
            text: qsTrId('id_receive')
            action: Action {
                enabled: UtilJS.effectiveVisible(self) && !self.archived && !wallet.locked && self.currentAccount
                shortcut: 'Ctrl+R'
                onTriggered: {
                    const context = self.context
                    const account = self.currentAccount
                    const network = account.network
                    const asset = context.getOrCreateAsset(network.liquid ? network.policyAsset : network.key)
                    const drawer = receive_drawer.createObject(self, { context, account, asset })
                    drawer.open()
                }
            }
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
        context: self.context
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
            context: account.context
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


    component HintPane: Pane {
        Layout.fillWidth: true
        Layout.topMargin: 10
        padding: 20
        background: Rectangle {
            border.width: 1
            border.color: '#1F222A'
            color: '#161921'
            radius: 4
        }
    }

    component Hint1Pane: HintPane {
        contentItem: RowLayout {
            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 600
                    text: 'A powerful hardware wallet for securing your Bitcoin.'
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    font.family: 'SF Compact Display'
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.3
                    text: 'Jade is an open-source hardware wallet for Bitcoin and Liquid assets.'
                    wrapMode: Label.WordWrap
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/hints/jade3d.svg'
            }
        }
    }

    component Hint2Pane: HintPane {
        contentItem: RowLayout {
            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 600
                    text: 'The Importance of Two-Factor Authentication'
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    font.family: 'SF Compact Display'
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.3
                    text: 'Protect your bitcoin with a second form of verification.'
                    wrapMode: Label.WordWrap
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/hints/cpu.svg'
            }
        }
    }
}
