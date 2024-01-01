import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MainPage {
    function openWallet(wallet) {
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.wallet === wallet) { // && !child.device) {
                stack_layout.currentIndex = i;
                return
            }
        }
        wallet_view.createObject(stack_layout, { wallet })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallets
    }
    function openDevice(device) {
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
            if (child.wallet?.xpubHashId === device.xpubHashId) {
                stack_layout.currentIndex = i;
                console.log('switch to existing wallet view with same xpubhashid', i)
                return
            }
        }

        if (device instanceof JadeDevice && device.state === JadeDevice.StateUninitialized) {
            jade_notification_dialog.createObject(window, { device }).open()
            return
        }

        if (device instanceof LedgerDevice) {
            // TODO ignore connected ledger device for now
            return
        }

        console.log('create view for device', device)
        wallet_view.createObject(stack_layout, { device })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallets
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
                side_bar.currentView = SideBar.View.Wallets
            }
            return
        }

        if (WalletManager.wallets.length === 1 && current_index >= 0) {
            stack_layout.currentIndex = current_index
            side_bar.currentView = SideBar.View.Wallets
            return
        }

        const wallet = WalletManager.wallets[0] ?? null
        wallet_view.createObject(stack_layout, { wallet })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallets
    }
    function closeWallet(wallet) {
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.wallet === wallet) {
                stack_layout.currentIndex = i - 1
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

    property Navigation navigation: Navigation {}
    property Constants constants: Constants {}

    Action {
        id: preferences_action
        onTriggered: {
            preferences_dialog.createObject(self).open()
            wallets_drawer.close()
            side_bar.currentView = SideBar.View.Preferences
        }
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

    id: self
    leftPadding: side_bar.width
    rightPadding: 0
    title: stack_layout.currentItem?.title ?? ''
    contentItem: Page {
        background: null
        header: AppUpdateBanner {
        }
        contentItem: GStackLayout {
            id: stack_layout
            currentIndex: 0
            WalletsView {
                id: wallets_view
                enabled: StackLayout.isCurrentItem
                focus: StackLayout.isCurrentItem
                onOpenWallet: (wallet) => self.openWallet(wallet)
                onOpenDevice: (device) => self.openDevice(device)
                onCreateWallet: self.openWallet(null)
            }
        }
    }

    Component {
        id: wallet_view
        WalletView {
            enabled: StackLayout.isCurrentItem
            onOpenWallet: (wallet) => self.openWallet(wallet)
            onCloseWallet: (wallet) => self.closeWallet(wallet)
            onRemoveWallet: (wallet) => remove_wallet_dialog.createObject(self, { wallet }).open()
        }
    }

    Component {
        id: remove_wallet_dialog
        RemoveWalletDialog {
            onRemoveWallet: (wallet) => {
                self.removeWallet(wallet)
            }
        }
    }

    JadeFirmwareController {
        id: firmware_controller
        enabled: true
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
        x: -side_bar.width
        Behavior on x {
            SmoothedAnimation {
                velocity: 200
            }
        }
        onPreferencesClicked: preferences_action.trigger()
        onWalletsClicked: openWallets()
    }


    Connections {
        target: DeviceManager
        function onDeviceAdded(device) {
            self.openDevice(device)
        }
    }

    Component {
        id: jade_notification_dialog
        JadeNotificationDialog {
            onSetupClicked: (device) => {
                self.openDevice(device)
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
            selfopenDevice(device)
        }
    }

    Component {
        id: preferences_dialog
        PreferencesView {
            onClosed: {
                side_bar.currentView = SideBar.View.Wallets
                destroy()
            }
        }
    }
}
