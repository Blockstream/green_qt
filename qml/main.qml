import Blockstream.Green
import Blockstream.Green.Core
import QtMultimedia
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ApplicationWindow {
    readonly property WalletView currentWalletView: stack_layout.currentWalletView
    readonly property Wallet currentWallet: currentWalletView?.wallet ?? null
    readonly property Account currentAccount: currentWalletView?.currentAccount ?? null

    property Navigation navigation: Navigation {}
    property Constants constants: Constants {}

    function openWallet(wallet) {
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.wallet === wallet && !child.device) {
                stack_layout.currentIndex = i;
                return
            }
        }
        wallet_view.createObject(stack_layout, { wallet })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallets
    }

    function openDevice(device) {
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.device === device) {
                stack_layout.currentIndex = i;
                return
            }
        }
        wallet_view.createObject(stack_layout, { device })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallets
    }

    function openWallets() {
        if (wallets_drawer.visible) {
            wallets_drawer.close()
            return
        }

        if (DeviceManager.count > 0) {
            wallets_drawer.open()
            return;
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
            stack_layout.currentIndex = 3
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


    JadeFirmwareController {
        id: firmware_controller
        enabled: true
    }

    JadeDeviceSerialPortDiscoveryAgent {
    }

    Connections {
        target: DeviceManager
        function onDeviceAdded(device) {
            if (device instanceof JadeDevice && device.state === JadeDevice.StateUninitialized) {
                jade_notification_dialog.createObject(window, { device }).open()
            }
        }
    }

    Component {
        id: jade_notification_dialog
        JadeNotificationDialog {
            onSetupClicked: (device) => {
                window.openDevice(device)
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
            window.openWallet(wallet)
        }
        onDeviceClicked: (device) => {
            wallets_drawer.close()
            window.openDevice(device)
        }
    }

    SideBar {
        id: side_bar
        height: parent.height
        parent: Overlay.overlay
        z: 1
        onBlockstreamClicked: {
            stack_layout.currentIndex = 1
            side_bar.currentView = SideBar.View.Blockstream
            wallets_drawer.close()
        }
        onPreferencesClicked: {
            stack_layout.currentIndex = 1
            side_bar.currentView = SideBar.View.Preferences
            wallets_drawer.close()
        }
        onWalletsClicked: openWallets()
    }

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
        if (currentWallet?.persisted) {
            Settings.updateRecentWallet(currentWallet.id)
        }
    }
    minimumWidth: 1024
    minimumHeight: 768
    visible: true
    color: constants.c800
    title: {
        const parts = env === 'Development' ? [navigation.description] : []
        if (currentWallet) {
            parts.push(font_metrics.elidedText(currentWallet.name, Qt.ElideRight, window.width / 3));
            if (currentAccount) parts.push(font_metrics.elidedText(UtilJS.accountName(currentAccount), Qt.ElideRight, window.width / 3));
        }
        parts.push('Blockstream Green');
        if (env !== 'Production') parts.push(`[${env}]`)
        return parts.join(' - ');
    }
    Label {
        parent: Overlay.overlay
        visible: false
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 4
        z: 1000
        HoverHandler {
            id: debug_focus_hover_handler
        }
        opacity: debug_focus_hover_handler.hovered ? 1.0 : 0.3
        background: Rectangle {
            color: Qt.rgba(1, 0, 0, 0.8)
            radius: 4
            border.width: 2
            border.color: 'black'
        }
        padding: 8
        text: {
            const parts = []
            let item = activeFocusItem
            while (item) {
                parts.unshift((''+item).split('(')[0])
                item = item.parent
            }
            return parts.join(' > ')
        }
    }
    FontMetrics {
        id: font_metrics
    }
    RowLayout {
        id: main_layout
        anchors.fill: parent
        spacing: 0
        Item {
            Layout.minimumWidth: side_bar.width
        }
        StackLayout {
            id: stack_layout
            Layout.fillWidth: true
            Layout.fillHeight: true
            readonly property WalletView currentWalletView: currentIndex < 0 ? null : (stack_layout.children[currentIndex].currentWalletView || null)
            BlockstreamView {
            }
            PreferencesView {
            }
            LedgerDevicesView {
            }
            WalletsView {
                title: qsTrId('id_wallets')
                focus: StackLayout.isCurrentItem
                onOpenWallet: (wallet) => window.openWallet(wallet)
                onOpenDevice: (device) => window.openDevice(device)
                onCreateWallet: window.openWallet(null)
            }
        }
    }

    Component.onCompleted: openWallets()

    Component {
        id: wallet_view
        WalletView {
            onOpenWallet: (wallet) => window.openWallet(wallet)
        }
    }

    AnalyticsConsentDialog {
        property real offset_y
        id: consent_dialog
        x: parent.width - consent_dialog.width - constants.s2
        y: parent.height - consent_dialog.height - constants.s2 - 30 + consent_dialog.offset_y
        // by default dialogs height depends on y, break that dependency to avoid binding loop on y
        height: implicitHeight
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

    Component {
        id: remove_wallet_dialog
        RemoveWalletDialog {}
    }

    readonly property bool scannerAvailable: (media_devices.item?.videoInputs?.length > 0) ?? false
    Loader {
        id: media_devices
        asynchronous: true
        active: true
        sourceComponent: MediaDevices {
        }
    }

    Shortcut {
        sequence: StandardKey.New
        onActivated: onboard_dialog.showNormal()
    }
}
