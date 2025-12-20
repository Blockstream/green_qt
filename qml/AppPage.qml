import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    signal crashClicked

    function openPreferences() {
        if (side_bar.currentView === SideBar.View.Preferences) {
            return
        }
        preferences_dialog.createObject(self).open()
        wallets_drawer.close()
        side_bar.currentView = SideBar.View.Preferences
    }
    function openWallet(wallet) {
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.wallet === wallet) { // && !child.device) {
                stack_layout.currentIndex = i;
                side_bar.currentWalletView = stack_layout.itemAt(i)
                return
            }
        }
        wallet_view.createObject(stack_layout, { wallet })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallet
    }
    function openDevice(device, options) {
        if (stack_layout.currentItem?.device) {
            console.log('current view has device assigned')
            return
        }

        if (stack_layout.currentItem?.wallet) {
            console.log('current view has wallet')
            if (stack_layout.currentItem.wallet.context) {
                console.log('    but wallet has context')
                return
            }
        }

        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (!(child instanceof WalletView)) continue
            if (child.device === device) {
                stack_layout.currentIndex = i;
                console.log('switch to existing device view', i)
                return
            }
            if (child.wallet && device.session && child.wallet.xpubHashId === device.session.xpubHashId) {
                stack_layout.currentIndex = i;
                console.log('switch to existing wallet view with same xpubhashid', i)
                return
            }
        }

        if (options?.prompt ?? true) {
            if (device instanceof JadeDevice && device.state === JadeDevice.StateUninitialized) {
                jade_notification_dialog.createObject(window, { device }).open()
                return
            }

            if (device instanceof LedgerDevice) {
                // TODO ignore connected ledger device for now
                return
            }
        }

        console.log('create view for device', device)
        wallet_view.createObject(stack_layout, { device })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallet
    }
    function openWallets() {
        if (wallets_drawer.visible) {
            wallets_drawer.close()
            return
        }

        let current_index = -1
        let current_wallet
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView) {
                current_index = i
                current_wallet = child.wallet
                break
            }
        }

        if (WalletManager.wallets.length > 1 && current_index < 0) {
            stack_layout.currentIndex = 0
            return
        }

        if (current_index >= 0) {
            if (current_wallet || WalletManager.wallets.length > 0) {
                wallets_drawer.open()
            } else {
                stack_layout.currentIndex = current_index
                side_bar.currentView = SideBar.View.Wallet
            }
            return
        }

        if (WalletManager.wallets.length === 1 && current_index >= 0) {
            stack_layout.currentIndex = current_index
            side_bar.currentView = SideBar.View.Wallet
            return
        }

        const wallet = WalletManager.wallets[0] ?? null
        wallet_view.createObject(stack_layout, { wallet })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallet
    }
    function closeWallet(wallet) {
        stack_layout.currentIndex = 0
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.wallet === wallet) {
                child.destroy()
                break
            }
        }
    }
    function closeDevice(device) {
        stack_layout.currentIndex = 0
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.device === device) {
                child.destroy()
                break
            }
        }
    }
    function removeWallet(wallet) {
        self.closeWallet(wallet)
        WalletManager.removeWallet(wallet)
        Analytics.recordEvent('wallet_delete')
    }
    property Constants constants: Constants {}

    Action {
        id: preferences_action
        onTriggered: self.openPreferences()
        shortcut: 'Ctrl+,'
    }

    StackView.onActivating: {
        const device = DeviceManager.defaultDevice()
        if (device instanceof JadeDevice) {
            self.openDevice(device)
        } else {
            self.openWallets()
        }
    }
    StackView.onActivated: side_bar.x = 0

    AppUpdateController {
        id: update_controller
    }

    id: self
    leftPadding: side_bar.width
    rightPadding: 0
    bottomPadding: 0
    title: stack_layout.currentItem?.title ?? ''
    contentItem: Page {
        background: null
        contentItem: GStackLayout {
            id: stack_layout
            currentIndex: 0
            onCurrentIndexChanged: stack_layout.currentItem.forceActiveFocus()
            WalletsView {
                enabled: StackLayout.isCurrentItem
                focus: StackLayout.isCurrentItem
                onOpenWallet: (wallet) => self.openWallet(wallet)
                onOpenDevice: (device) => self.openDevice(device)
                onCreateWallet: self.openWallet(null)
                AnalyticsView {
                    name: 'Home'
                    active: stack_layout.currentIndex === 0
                }
            }
        }

        NotificationToast {
            parent: Overlay.overlay
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 20
            anchors.bottomMargin: 20
            width: Math.min(400, parent.width * 0.4)
            notifications: UtilJS.flatten(stack_layout.currentItem?.notifications, update_controller.notification).filter(notification => !notification.dismissed)
        }

        footer: ColumnLayout {
            spacing: 0
            TorFooter {
                Layout.fillWidth: true
            }
            Bip21Footer{
                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: wallet_view
        WalletView {
            enabled: StackLayout.isCurrentItem
            onOpenWallet: (wallet) => self.openWallet(wallet)
            onCloseWallet: (wallet) => self.closeWallet(wallet)
            onCloseDevice: (device) => self.closeDevice(device)
            onRemoveWallet: (wallet) => remove_wallet_dialog.createObject(self, { wallet }).open()
        }
    }

    Component {
        id: remove_wallet_dialog
        RemoveWalletDialog {
            onRemoveWallet: (wallet) => {
                self.removeWallet(wallet)
                stack_layout.currentIndex = 0
            }
        }
    }

    JadeDeviceSerialPortDiscoveryAgent {
    }
    DeviceDiscoveryAgent {
    }

    SideBar {
        id: side_bar
        height: parent?.height ?? 0
        parent: Overlay.overlay
        z: 1
        x: -side_bar.implicitWidth
        currentWalletView: {
            const view = stack_layout.itemAt(stack_layout.currentIndex)
            return view instanceof WalletView ? view : null
        }
        Behavior on x {
            SmoothedAnimation {
                velocity: 200
            }
        }
        onPreferencesClicked: preferences_action.trigger()
        onWalletsClicked: openWallets()
        onCrashClicked: self.crashClicked()
        onSimulateNotificationClicked: (type) => {
            let context = stack_layout.currentItem?.wallet?.context

            if (!context && WalletManager.wallets.length > 0) {
                const wallet = WalletManager.wallets[0]
                if (wallet && wallet.context) {
                    context = wallet.context
                }
            }

            if (!context) {
                console.log('No context available for notification simulation')
                return
            }

            console.log('Simulating notification of type:', type)

            switch (type) {
                case 'system':
                    context.addTestNotification('This is a test system notification')
                    break
                case 'outage':
                    context.addTestOutageNotification()
                    break
                case '2fa_reset':
                    context.addTestTwoFactorResetNotification()
                    break
                case '2fa_expired':
                    context.addTestTwoFactorExpiredNotification()
                    break
                case 'warning':
                    context.addTestWarningNotification()
                    break
                case 'update':
                    context.addTestUpdateNotification()
                    break
                default:
                    console.log('Unknown notification type:', type)
            }
        }
    }


    Connections {
        target: DeviceManager
        function onDeviceAdded(device) {
            self.openDevice(device)
        }
        function onDeviceConnected(device) {
            self.openDevice(device)
        }
    }

    Component {
        id: jade_notification_dialog
        JadeNotificationDialog {
            onSetupClicked: (device) => {
                self.openDevice(device, { prompt: false })
                close()
            }
            onClosed: destroy()
        }
    }

    WalletsDrawer {
        id: wallets_drawer
        leftMargin: side_bar.width
        onWalletClicked: (wallet) => {
            wallets_drawer.close()
            self.openWallet(wallet)
        }
        onDeviceClicked: (device) => {
            wallets_drawer.close()
            self.openDevice(device)
        }
    }

    Component {
        id: preferences_dialog
        PreferencesDialog {
            onClosed: {
                side_bar.currentView = side_bar.currentWalletView ? SideBar.View.Wallet : SideBar.View.Wallets
                destroy()
            }
        }
    }
}
