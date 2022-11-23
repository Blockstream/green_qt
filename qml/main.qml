import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

ApplicationWindow {
    id: window

    readonly property WalletView currentWalletView: stack_layout.currentWalletView
    readonly property Wallet currentWallet: currentWalletView ? currentWalletView.wallet : null
    readonly property Account currentAccount: currentWalletView ? currentWalletView.currentAccount : null

    property Navigation navigation: Navigation {
        location: '/home'
    }
    function link(url, text) {
        return `<style>a:link { color: "#00B45A"; text-decoration: none; }</style><a href="${url}">${text || url}</a>`
    }

    function iconFor(target) {
        if (target instanceof Wallet) return iconFor(target.network)
        if (target instanceof Network) return iconFor(target.key)
        switch (target) {
            case 'liquid':
                return 'qrc:/svg/liquid.svg'
            case 'testnet-liquid':
                return 'qrc:/svg/testnet-liquid.svg'
            case 'bitcoin':
                return 'qrc:/svg/btc.svg'
            case 'testnet':
                return 'qrc:/svg/btc_testnet.svg'
        }
        return ''
    }

    property Constants constants: Constants {}

    function formatTransactionTimestamp(tx) {
        return new Date(tx.created_at_ts / 1000).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
    }

    function accountName(account) {
        if (!account) return ''
        if (account.name !== '') return account.name
        if (account.mainAccount) return qsTrId('id_main_account')
        return qsTrId('Account %1').arg(account.pointer)
    }

    function segmentationNetwork(network) {
        const segmentation = {}
        segmentation.network
            = network.liquid ? 'liquid'
            : network.mainnet ? 'mainnet'
            : 'testnet'
        segmentation.security
            = network.electrum ? 'singlesig'
            : 'multisig'
        return segmentation
    }

    function segmentationOnBoard({ flow, network, security }) {
        const segmentation = {}
        if (flow) segmentation.flow = flow
        if (network) segmentation.network = network
        if (security) segmentation.security = security
        return segmentation
    }

    function segmentationSession(wallet) {
        const segmentation = segmentationNetwork(wallet.network)
        const app_settings = []
        if (Settings.useTor) app_settings.push('tor')
        if (Settings.useProxy) app_settings.push('proxy')
        if (Settings.enableTestnet) app_settings.push('testnet')
        if (Settings.usePersonalNode) app_settings.push('electrum_server')
        if (Settings.enableSPV) app_settings.push('spv')
        segmentation.app_settings = app_settings.join(',')
        if (wallet.device instanceof JadeDevice) {
            segmentation.brand = 'Blockstream'
            segmentation.model = wallet.device.versionInfo.BOARD_TYPE
            segmentation.firmware = wallet.device.version
            segmentation.connection = 'USB'
        }
        if (wallet.device instanceof LedgerDevice) {
            segmentation.brand = 'Ledger'
            segmentation.model
                = wallet.device.type === Device.LedgerNanoS ? 'Ledger Nano S'
                : wallet.device.type === Device.LedgerNanoX ? 'Ledger Nano X'
                : 'Unknown'
            segmentation.firmware = wallet.device.appVersion
            segmentation.connection = 'USB'
        }
        return segmentation
    }

    function segmentationFirmwareUpdate(device) {
        const segmentation = {}
        const app_settings = []
        if (Settings.useTor) app_settings.push('tor')
        if (Settings.useProxy) app_settings.push('proxy')
        if (Settings.enableTestnet) app_settings.push('testnet')
        if (Settings.usePersonalNode) app_settings.push('electrum_server')
        if (Settings.enableSPV) app_settings.push('spv')
        segmentation.app_settings = app_settings.join(',')
        if (device instanceof JadeDevice) {
            segmentation.brand = 'Blockstream'
            segmentation.model = device.versionInfo.BOARD_TYPE
            segmentation.firmware = device.version
            segmentation.connection = 'USB'
        }
        return segmentation
    }

    function segmentationShareTransaction(account, { method = 'copy' } = {}) {
        const segmentation = segmentationSession(account.wallet)
        segmentation.method = method
        return segmentation;
    }

    function segmentationWalletLogin(wallet, { method }) {
        const segmentation = segmentationSession(wallet)
        segmentation.method = method
        return segmentation
    }

    function segmentationSubAccount(account) {
        const segmentation = segmentationSession(account.wallet)
        segmentation.account_type = account.type
        return segmentation
    }

    function segmentationReceiveAddress(account, type) {
        const segmentation = segmentationSubAccount(account)
        segmentation.type = type
        segmentation.media = 'text'
        segmentation.method = 'copy'
        return segmentation
    }

    function segmentationTransaction(account, { address_input, transaction_type, with_memo }) {
        const segmentation = segmentationSubAccount(account)
        segmentation.address_input = address_input // [paste, scan, bip21]
        segmentation.transaction_type = transaction_type // [send, sweep, bump]
        segmentation.with_memo = with_memo
        return segmentation
    }

    function segmentationWalletActive(wallet) {
        const segmentation = segmentationSession(wallet)
        let accounts_funded = 0
        const accounts_types = new Set
        const key = wallet.network.liquid ? wallet.network.policyAsset : 'btc'
        for (let i = 0; i < wallet.accounts.length; ++i) {
            const account = wallet.accounts[i]
            accounts_types.add(account.type)
            if (account.json.satoshi[key] > 0 || Object.keys(account.json.satoshi).length > 1) {
                accounts_funded ++
            }
        }
        segmentation.wallet_funded = accounts_funded > 0
        segmentation.accounts_funded = accounts_funded
        segmentation.accounts = wallet.accounts.length
        segmentation.accounts_types = Array.from(accounts_types).join(',')
        return segmentation
    }

    function renameAccount(account, text, active_focus) {
        if (account.rename(text, active_focus)) {
            Analytics.recordEvent('account_rename', segmentationSubAccount(account))
        }
    }

    function dynamicScenePosition(item, x, y) {
        const target = item
        while (item) {
            item.x
            item.y
            item = item.parent
        }
        return target.mapToItem(null, x, y)
    }

    x: Settings.windowX
    y: Settings.windowY
    width: Settings.windowWidth
    height: Settings.windowHeight

    onXChanged: Settings.windowX = x
    onYChanged: Settings.windowY = y
    onWidthChanged: Settings.windowWidth = width
    onHeightChanged: Settings.windowHeight = height
    onCurrentWalletChanged: {
        if (currentWallet && currentWallet.persisted) {
            Settings.updateRecentWallet(currentWallet.id)
        }
    }

    minimumWidth: 900
    minimumHeight: 600
    visible: true
    color: constants.c900
    title: {
        const parts = Qt.application.arguments.indexOf('--debugnavigation') > 0 ? [navigation.location] : []
        if (currentWallet) {
            parts.push(font_metrics.elidedText(currentWallet.name, Qt.ElideRight, window.width / 3));
            if (currentAccount) parts.push(font_metrics.elidedText(accountName(currentAccount), Qt.ElideRight, window.width / 3));
        }
        parts.push('Blockstream Green');
        if (build_type !== 'release') parts.push(`[${build_type}]`)
        return parts.join(' - ');
    }
    FontMetrics {
        id: font_metrics
    }

    RowLayout {
        id: main_layout
        anchors.fill: parent
        spacing: 0
        SideBar {
            Layout.fillHeight: true
        }
        ColumnLayout {
            StackLayout {
                id: stack_layout
                Layout.fillWidth: true
                Layout.fillHeight: true
                readonly property WalletView currentWalletView: currentIndex < 0 ? null : (stack_layout.children[currentIndex].currentWalletView || null)
                Binding on currentIndex {
                    delayed: true
                    value: {
                        let index = stack_layout.currentIndex
                        for (let i = 0; i < stack_layout.children.length; ++i) {
                            const child = stack_layout.children[i]
                            if (!(child instanceof Item)) continue
                            if (child.active && child.enabled) index = i
                        }
                        return index
                    }
                }
                HomeView {
                    readonly property bool active: navigation.path === '/home'
                }
                BlockstreamView {
                    id: blockstream_view
                    readonly property bool active: navigation.path === '/blockstream'
                }
                PreferencesView {
                    readonly property bool active: navigation.path === '/preferences'
                }
                JadeView {
                    id: jade_view
                    readonly property bool active: navigation.path.startsWith('/jade')
                }
                LedgerDevicesView {
                    id: ledger_view
                    readonly property bool active: navigation.path.startsWith('/ledger')
                }
                NetworkView {
                    network: 'bitcoin'
                    title: qsTrId('id_bitcoin_wallets')
                }
                NetworkView {
                    network: 'liquid'
                    title: qsTrId('id_liquid_wallets')
                }
                NetworkView {
                    enabled: Settings.enableTestnet
                    network: 'testnet-liquid'
                    title: qsTrId('id_liquid_testnet_wallets')
                }
                NetworkView {
                    enabled: Settings.enableTestnet
                    network: 'testnet'
                    title: qsTrId('id_testnet_wallets')
                }
            }
        }
    }

    AnalyticsConsentDialog {
        property real offset_y
        x: parent.width - width - constants.s2
        y: parent.height - height - constants.s2 - 30 + offset_y
        visible: Settings.analytics === ''
        enter: Transition {
            SequentialAnimation {
                PropertyAction { property: 'x'; value: 0 }
                PropertyAction { property: 'offset_y'; value: 100 }
                PropertyAction { property: 'opacity'; value: 0 }
                PauseAnimation { duration: 2000 }
                ParallelAnimation {
                    NumberAnimation { property: 'opacity'; to: 1; easing.type: Easing.OutCubic; duration: 1000 }
                    NumberAnimation { property: 'offset_y'; to: 0; easing.type: Easing.OutCubic; duration: 1000 }
                }
            }
        }
    }

    DialogLoader {
        active: navigation.path.match(/\/signup$/)
        dialog: SignupDialog {
            onRejected: navigation.pop()
        }
    }

    DialogLoader {
        active: navigation.path.match(/\/restore$/)
        dialog: RestoreDialog {
            onRejected: navigation.pop()
        }
    }

    DialogLoader {
        properties: {
            const [,, wallet_id] = navigation.path.split('/')
            const wallet = WalletManager.wallet(wallet_id)
            return { wallet }
        }
        active: properties.wallet && !properties.wallet.ready
        dialog: LoginDialog {
            onRejected: navigation.pop()
        }
    }

    DebugActiveFocus {
    }

    Component {
        id: create_account_dialog
        CreateAccountDialog {}
    }

    Component {
        id: remove_wallet_dialog
        RemoveWalletDialog {}
    }

    Component {
        id: export_transactions_popup
        Popup {
            required property Account account
            id: dialog
            anchors.centerIn: Overlay.overlay
            closePolicy: Popup.NoAutoClose
            modal: true
            Overlay.modal: Rectangle {
                color: "#70000000"
            }
            onClosed: destroy()
            onOpened: controller.save()
            ExportTransactionsController {
                id: controller
                account: dialog.account
                onSaved: dialog.close()
            }
            BusyIndicator {}
        }
    }
}
