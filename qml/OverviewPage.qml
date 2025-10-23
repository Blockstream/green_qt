import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Page {
    enum View {
        Home,
        Transactions,
        Security,
        Settings
    }

    signal jadeDetailsClicked()
    signal logout()

    function showView(view) {
        self.view = view
    }

    required property Context context
    readonly property Wallet wallet: self.context.wallet
    property int view: OverviewPage.Home

    readonly property var notifications: self.context?.notifications

    Connections {
        target: self.context
        function onAutoLogout() {
            self.logout()
        }
        function onNotificationTriggered(notification) {
            if (notification instanceof SystemNotification) {
                notifications_drawer.open()
            } else {
                notification_drawer.createObject(self, { notification }).open()
            }
        }
    }

    function checkDeviceMatches() {
        if (self.context.wallet.login instanceof DeviceData) {
            if (!self.context.device) return true
            if (!self.context.device.session) return true
            if (self.context.device.session.xpubHashId !== self.context.xpubHashId) return false
        }
        return true
    }

    function openCreateAccountDrawer({ dismissable = true } = {}) {
        if (!self.checkDeviceMatches()) return
        const network = self.context.primaryNetwork()
        const id = network.liquid ? network.policyAsset : 'btc'
        const asset = self.context.getOrCreateAsset(id)
        const drawer = create_account_drawer.createObject(self, { context: self.context, asset, dismissable })
        drawer.open()
    }

    function openSendDrawer(url = '') {
        const context = self.context
        const account = null
        const network = null
        const asset = context.getOrCreateAsset(network.liquid ? network.policyAsset : 'btc')
        const drawer = send_drawer.createObject(self, { context, account, asset, url })
        drawer.open()
    }

    function transactionConfirmations(transaction) {
        if (transaction.data.block_height === 0) return 0;
        return 1 + transaction.account.session.block.block_height - transaction.data.block_height;
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
            case 'p2tr':
                return 'p2tr'
            default:
                console.warn(`missing localized label for ${label}`)
                console.trace()
                return label
        }
    }

    Component {
        id: notification_drawer
        NotificationDrawer {
        }
    }

    component NotificationDrawer: AbstractDrawer {
        required property Notification notification
        onClosed: drawer.destroy()

        id: drawer
        edge: Qt.RightEdge
        minimumContentWidth: 450
        contentItem: GStackView {
            id: stack_view
            initialItem: {
                if (drawer.notification instanceof OutageNotification) {
                    return outage_page
                } else if (drawer.notification instanceof TwoFactorExpiredNotification) {
                    return two_factor_expired_page
                } else {
                    console.log('unhandled notification trigger', notification)
                }
            }
        }
        Component {
            id: outage_page
            OutagePage {
                context: self.context
                onLoadFinished: drawer.close()
            }
        }
        Component {
            id: two_factor_expired_page
            TwoFactorExpiredSelectAccountPage {
                context: self.context
                notification: drawer.notification
                rightItem: CloseButton {
                    onClicked: drawer.close()
                }
                onClosed: drawer.close()
            }
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

    // Controller {
    //     id: controller
    //     context: self.context
    // }

    StackView.onActivated: {
        self.forceActiveFocus()
        Analytics.recordEvent('wallet_active', AnalyticsJS.segmentationWalletActive(Settings, self.context))
    }

    id: self
    background: null
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    title: self.wallet.name
    spacing: 0

    Action {
        id: open_assets_drawer_action
        onTriggered: {
            const drawer = assets_drawer.createObject(self, { context: self.context })
            drawer.open()
        }
        shortcut: 'Ctrl+A'
    }

    header: WalletViewHeader {
        onJadeDetailsClicked: self.jadeDetailsClicked()
        onSettingsClicked: settings_dialog.createObject(self, { context: self.context }).open()
        onLogoutClicked: self.logout()
        onArchivedAccountsClicked: archived_accounts_dialog.createObject(self, { context: self.context }).open()
        onStatusClicked: status_drawer.open()
        onNotificationsClicked: notifications_drawer.open()
        onReportBugClicked: {
            const drawer = support_drawer.createObject(self, {
                context: self.context,
                type: 'incident',
                subject: 'Bug report from green_qt'
            })
            drawer.open()
        }
        id: wallet_header
        context: self.context
        wallet: self.wallet
        view: self.view
    }
    Action {
        enabled: UtilJS.effectiveVisible(self)
        shortcut: 'Ctrl+L'
        onTriggered: self.logout()
    }
    StatusDrawer {
        id: status_drawer
        context: self.context
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
            onCreated: (account) => {}
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
            onAccountClicked: (account) => {
                self.showView(OverviewPage.Transactions)
                transactions_page.showTransactions({ account })
            }
        }
    }

    Component {
        id: asset_drawer
        AssetDrawer {
            onAccountClicked: (asset, account) => {
                self.showView(OverviewPage.Transactions)
                transactions_page.showTransactions({ account, asset })
            }
            onTransactionsClicked: (asset) => {
                self.showView(OverviewPage.Transactions)
                transactions_page.showTransactions({ asset })
            }
        }
    }

    Component {
        id: update_unspents_drawer
        UpdateUnspentsDrawer {
        }
    }

    Component {
        id: archived_accounts_dialog
        ArchivedAccountsDialog {
        }
    }

    contentItem: StackLayout {
        currentIndex: self.view
        HomePage {
            context: self.context
            onAssetClicked: (asset) => asset_drawer.createObject(self, { context: self.context, asset }).open()
            onTransactionClicked: (transaction) => transaction_details_drawer.createObject(self, { context: self.context, transaction }).open()
            onTransactionsClicked: {
                self.showView(OverviewPage.Transactions)
                transactions_page.showTransactions()
            }
        }
        TransactionsPage {
            id: transactions_page
            context: self.context
            onTransactionClicked: (transaction) => transaction_details_drawer.createObject(self, { context: self.context, transaction }).open()
            onAddressClicked: (address) => address_details_drawer.createObject(self, { context: self.context, address }).open()
        }
        Page {
            background: null
            contentItem: null
        }
        Page {
            background: null
            contentItem: null
        }
    }

    Component {
        id: genuine_check_dialog
        JadeGenuineCheckDialog {
            id: dialog
            autoCheck: true
            onGenuine: {
                if (Settings.rememberDevices) {
                    const efusemac = self.context.device.versionInfo.EFUSEMAC
                    Settings.registerEvent({ efusemac, result: 'genuine', type: 'jade_genuine_check' })
                }
                dialog.close()
            }
            onDiy: {
                if (Settings.rememberDevices) {
                    const efusemac = self.context.device.versionInfo.EFUSEMAC
                    Settings.registerEvent({ efusemac, result: 'diy', type: 'jade_genuine_check' })
                }
                dialog.close()
            }
            onSkip: {
                if (Settings.rememberDevices) {
                    const efusemac = self.context.device.versionInfo.EFUSEMAC
                    Settings.registerEvent({ efusemac, result: 'skip', type: 'jade_genuine_check' })
                }
                dialog.close()
            }
            onAbort: {
                dialog.close()
            }
        }
    }

    Component {
        id: support_drawer
        SupportDrawer {
        }
    }

    // component JadeGenuineHintPane: Pane {
    //     Layout.fillWidth: true
    //     Layout.topMargin: 10
    //     id: hint
    //     padding: 20
    //     background: Rectangle {
    //         border.width: 1
    //         border.color: '#1F222A'
    //         color: '#161921'
    //         radius: 4
    //     }
    //     visible: {
    //         const device = self.context.device
    //         if (device instanceof JadeDevice) {
    //             if (device.versionInfo.BOARD_TYPE === 'JADE_V2') {
    //                 return true
    //             }
    //         }
    //         return false
    //     }
    //     contentItem: RowLayout {
    //         ColumnLayout {
    //             Layout.fillWidth: true
    //             Label {
    //                 Layout.preferredWidth: 0
    //                 Layout.fillWidth: true
    //                 font.pixelSize: 12
    //                 font.weight: 600
    //                 text: 'Verify the authenticity of your Jade.'
    //                 wrapMode: Label.WordWrap
    //             }
    //             Label {
    //                 Layout.preferredWidth: 0
    //                 Layout.fillWidth: true
    //                 font.pixelSize: 11
    //                 font.weight: 400
    //                 opacity: 0.3
    //                 text: 'Quickly confirm your Jade’s authenticity and security.'
    //                 wrapMode: Label.WordWrap
    //             }
    //             PrimaryButton {
    //                 leftPadding: 24
    //                 rightPadding: 24
    //                 topPadding: 7
    //                 bottomPadding: 7
    //                 text: 'Genuine Check'
    //                 onClicked: {
    //                     const dialog = genuine_check_dialog.createObject(self, { device: self.context.device })
    //                     dialog.open()
    //                 }
    //             }
    //         }
    //         Image {
    //             Layout.alignment: Qt.AlignCenter
    //             source: 'qrc:/png/jade_genuine.png'
    //         }
    //     }
    // }
}
