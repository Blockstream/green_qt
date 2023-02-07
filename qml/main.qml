import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ApplicationWindow {
    readonly property WalletView currentWalletView: stack_layout.currentWalletView
    readonly property Wallet currentWallet: currentWalletView ? currentWalletView.wallet : null
    readonly property Account currentAccount: currentWalletView ? currentWalletView.currentAccount : null

    property Navigation navigation: Navigation {
        location: '/home'
    }

    property Constants constants: Constants {}

    id: window
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
            if (currentAccount) parts.push(font_metrics.elidedText(UtilJS.accountName(currentAccount), Qt.ElideRight, window.width / 3));
        }
        parts.push('Blockstream Green');
        if (env !== 'Production') parts.push(`[${env}]`)
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

    Loader2 {
        active: navigation.path.match(/\/signup$/)
        onActiveChanged: if (!active) object.close()
        sourceComponent: SignupDialog {
            visible: true
            onRejected: navigation.pop()
            onClosed: destroy()
        }
    }

    Loader2 {
        active: navigation.path.match(/\/restore$/)
        onActiveChanged: if (!active) object.close()
        sourceComponent: RestoreDialog {
            visible: true
            onRejected: navigation.pop()
            onClosed: destroy()
        }
    }

    Loader2 {
        property Wallet wallet: {
            const [,, wallet_id] = navigation.path.split('/')
            return WalletManager.wallet(wallet_id)
        }
        active: wallet && !wallet.ready
        onActiveChanged: if (!active) object.close()
        sourceComponent: LoginDialog {
            visible: true
            onRejected: navigation.pop()
            onClosed: destroy()
        }
    }

    Component {
        id: create_account_dialog
        CreateAccountDialog {}
    }

    Component {
        id: remove_wallet_dialog
        RemoveWalletDialog {}
    }
}
