import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal logout()

    required property Context context
    readonly property Wallet wallet: self.context.wallet
    property Account currentAccount: null
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

    function checkDeviceMatches() {
        if (self.context.wallet.login instanceof DeviceData) {
            if (!self.context.device) return false
            if (!self.context.device.session) return false
            if (self.context.device.session.xpubHashId !== self.context.xpubHashId) return false
        }
        return true
    }

    function openCreateAccountDrawer({ dismissable = true } = {}) {
        if (!self.checkDeviceMatches()) return
        const network = self.currentAccount?.network ?? self.context.primaryNetwork()
        const id = network.liquid ? network.policyAsset : 'btc'
        const asset = self.context.getOrCreateAsset(id)
        const drawer = create_account_drawer.createObject(self, { context: self.context, asset, dismissable })
        drawer.open()
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

    AnalyticsAlert {
        id: overview_alert
        screen: 'Overview'
        // TODO: which network to pass on the alert?
        // network: self.wallet.network.id
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

    StackView.onActivated: {
        Analytics.recordEvent('wallet_active', AnalyticsJS.segmentationWalletActive(Settings, self.context))
        const account = account_list_model.first()
        if (account) {
            self.currentAccount = account
        } else {
            Qt.callLater(() => {
                fresh_wallet_dialog.createObject(self, { context: self.context }).open()
            })
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
    spacing: 0
    property alias toolbarItem: wallet_header.toolbarItem

    Action {
        id: open_assets_drawer_action
        onTriggered: {
            const drawer = assets_drawer.createObject(self, { context: self.context })
            drawer.open()
        }
        shortcut: 'Ctrl+A'
    }

    header: WalletViewHeader {
        onAssetsClicked: open_assets_drawer_action.trigger()
        onSettingsClicked: settings_dialog.createObject(self, { context: self.context }).open()
        onLogoutClicked: self.logout()
        onArchivedAccountsClicked: archived_accounts_dialog.createObject(self, { context: self.context }).open()
        onNotificationsClicked: notifications_drawer.open()
        id: wallet_header
        context: self.context
        wallet: self.wallet
        currentAccount: self.currentAccount
        accountListWidth: accounts_list.width
    }
    footer: Item {
        implicitHeight: 16
    }

    Action {
        enabled: UtilJS.effectiveVisible(self)
        shortcut: 'Ctrl+L'
        onTriggered: self.logout()
    }
    NotificationsDrawer {
        id: notifications_drawer
        context: self.context
    }
    Component {
        id: settings_dialog
        WalletSettingsDialog {
        }
    }
    Component {
        id: create_account_drawer
        CreateAccountDrawer {
            onCreated: (account) => self.currentAccount = account
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
            onAccountClicked: (account) => self.switchToAccount(account)
        }
    }

    Component {
        id: asset_drawer
        AssetDrawer {
            onAccountClicked: (account) => self.switchToAccount(account)
        }
    }

    Component {
        id: archived_accounts_dialog
        ArchivedAccountsDialog {
        }
    }

    /*
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
                visible: self.currentAccount?.session?.events?.twofactor_reset?.is_active ?? false
                padding: 8
                leftPadding: 40
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                text: {
                    if (!self.currentAccount) return ''
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
    */

    Component {
        id: account_view_component
        AccountView {
            onTransactionClicked: (transaction) => transaction_details_drawer.createObject(self, { context: self.context, transaction }).open()
            onAddressClicked: (address) => address_details_drawer.createObject(self, { context: self.context, address }).open()
            onAssetClicked: (account, asset) => asset_drawer.createObject(self, { context: self.context, account, asset }).open()
        }
    }

    property var account_views: ({})
    function switchToAccount(account) {
        if (account) {
            // call later to ensure account list is updated after add/hide/show account
            Qt.callLater(() => {
                const context = self.context
                let account_view = account_views[account]
                if (!account_view) {
                    account_view = account_view_component.createObject(null, { context, account })
                    account_views[account] = account_view
                }
                if (stack_view.currentItem === account_view) return;
                stack_view.replace(account_view, StackView.Immediate)
                accounts_list.currentIndex = account_list_model.indexOf(account)
            })
        } else {
            stack_view.replace(stack_view.initialItem, StackView.Immediate)
        }
    }

    onCurrentAccountChanged: {
        if (self.currentAccount) {
            switchToAccount(self.currentAccount)
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
            contentItem: TListView {
                id: accounts_list
                model: account_list_model
                currentIndex: 0
                spacing: 5
                delegate: AccountDelegate {
                    onAccountClicked: account => self.currentAccount = account
                    onAccountArchived: account => {
                        let i = Math.max(0, account_list_model.indexOf(account) - 1)
                        if (account_list_model.accountAt(i) === account) i++
                        self.currentAccount = account_list_model.accountAt(i)
                    }
                }
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
    MultiEffect {
        anchors.fill: btns
        shadowBlur: 1.0
        shadowColor: 'black'
        shadowEnabled: true
        shadowVerticalOffset: 10
        source: btns
        blurMax: 64
    }
    MultiEffect {
        anchors.fill: btns
        shadowBlur: 1.0
        shadowColor: 'black'
        shadowEnabled: true
        shadowVerticalOffset: -5
        source: btns
        blurMax: 64
    }
    RowLayout {
        id: btns
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: constants.p3
        anchors.bottomMargin: constants.p3 * 2
        spacing: 5
        PrimaryButton {
            Layout.minimumWidth: 150
            icon.source: 'qrc:/svg/send.svg'
            text: qsTrId('id_send')
            action: Action {
                enabled: UtilJS.effectiveVisible(self) && self.checkDeviceMatches() && !self.context.watchonly && self.currentAccount && !(self.currentAccount.session.config?.twofactor_reset?.is_active ?? false)
                shortcut: 'Ctrl+S'
                onTriggered: {
                    const context = self.context
                    const account = self.currentAccount
                    const network = account.network
                    const asset = context.getOrCreateAsset(network.liquid ? network.policyAsset : 'btc')
                    const drawer = send_drawer.createObject(self, { context, account, asset })
                    drawer.open()
                }
            }
        }
        PrimaryButton {
            Layout.minimumWidth: 150
            icon.source: 'qrc:/svg/receive.svg'
            text: qsTrId('id_receive')
            action: Action {
                enabled: UtilJS.effectiveVisible(self) && self.checkDeviceMatches() && self.currentAccount && !(self.currentAccount.session.config?.twofactor_reset?.is_active ?? false)
                shortcut: 'Ctrl+R'
                onTriggered: {
                    const context = self.context
                    const account = self.currentAccount
                    const network = account.network
                    const asset = context.getOrCreateAsset(network.liquid ? network.policyAsset : 'btc')
                    const drawer = receive_drawer.createObject(self, { context, account, asset })
                    drawer.open()
                }
            }
        }
    }

    component HintPane: AbstractButton {
        Layout.fillWidth: true
        Layout.topMargin: 10
        id: hint
        padding: 20
        background: Rectangle {
            border.width: 1
            border.color: '#1F222A'
            color: Qt.lighter('#161921', hint.hovered ? 1.2 : 1)
            radius: 4
        }
    }

    component Hint1Pane: HintPane {
        onClicked: Qt.openUrlExternally('https://store.blockstream.com/products/blockstream-jade-hardware-wallet')
        contentItem: RowLayout {
            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    font.weight: 600
                    text: qsTrId('id_a_powerful_hardware_wallet_for')
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.3
                    text: qsTrId('id_jade_is_an_opensource_hardware')
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
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900001391763-How-does-Blockstream-Green-s-2FA-multisig-protection-work-')
        contentItem: RowLayout {
            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    font.weight: 600
                    text: qsTrId('id_the_importance_of_twofactor')
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.3
                    text: qsTrId('id_protect_your_bitcoin_with_a')
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
