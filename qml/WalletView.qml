import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    signal openWallet(Wallet wallet)
    signal removeWallet(Wallet wallet)
    signal closeWallet(Wallet wallet)
    signal closeDevice(Device device)

    property Wallet wallet
    property Device device
    readonly property Account currentAccount: stack_view.currentItem?.currentAccount ?? null
    readonly property var notifications: UtilJS.flatten(stack_view.currentItem?.notifications, login_alert.notification)

    function send(url) {
        if (stack_view.currentItem instanceof OverviewPage) {
            stack_view.currentItem.openSendDrawer(url)
        }
    }

    function openJadeDetailsDrawer() {
        if (Qt.application.arguments.indexOf('--debugjade') > 0) {
            const drawer = jade_details_drawer.createObject(self, { device: self.device })
            drawer.open()
        }
    }

    readonly property OverviewPage overviewPage
        : stack_view.currentItem instanceof OverviewPage
        ? stack_view.currentItem as OverviewPage
        : null

    AnalyticsAlert {
        id: login_alert
        screen: 'Login'
    }
    Component.onCompleted: {
        const wallet = self.wallet
        if (!wallet) {
            if (self.device instanceof JadeDevice) {
                stack_view.push(jade_page, { device: self.device, login: true }, StackView.Immediate)
            } else {
                stack_view.push(terms_of_service_page, {}, StackView.Immediate)
            }
        } else if (wallet.context) {
            stack_view.push(loading_page, { context: wallet.context }, StackView.Immediate)
        } else if (wallet.login instanceof WatchonlyData) {
            stack_view.push(watch_only_login_page, { wallet }, StackView.Immediate)
        } else if (wallet.login instanceof DeviceData) {
            stack_view.push(device_page, { wallet }, StackView.Immediate)
        } else if (wallet.login instanceof PinData) {
            stack_view.push(pin_login_page, { wallet }, StackView.Immediate)
        } else {
            stack_view.push(restore_wallet_page, { wallet }, StackView.Immediate)
        }
    }
    id: self
    title: stack_view.currentItem?.title ?? null
    contentItem: GStackView {
        id: stack_view
        focus: true
    }

    Component {
        id: device_page
        DevicePage {
            padding: 60
            onDeviceSelected: (device) => {
                if (device instanceof JadeDevice) {
                    stack_view.push(jade_page, { device, login: true })
                }
                if (device instanceof LedgerDevice) {
                    stack_view.push(ledger_page, { device })
                }
            }
            onRemoveClicked: self.removeWallet(self.wallet)
            onCloseClicked: self.closeWallet(self.wallet)
        }
    }

    Component {
        id: jade_page
        JadePage {
            onLoginFinished: (context) => {
                self.wallet = context.wallet
                stack_view.replace(null, loading_page, { context }, StackView.PushTransition)
            }
            onFirmwareUpdated: stack_view.pop()
            onCloseClicked: self.closeDevice(self.device)
            onDetailsClicked: self.openJadeDetailsDrawer()
        }
    }

    Component {
        id: qrmode_page
        JadeQRModePage {
        }
    }

    Component {
        id: ledger_page
        LedgerPage {
            onLoginFinished: (context) => {
                self.wallet = context.wallet
                stack_view.replace(null, loading_page, { context }, StackView.PushTransition)
            }
            onLoginFailed: stack_view.pop()
        }
    }

    Component {
        id: terms_of_service_page
        TermOfServicePage {
            onStart: stack_view.push(secure_funds_page)
            onCloseClicked: self.closeWallet(self.wallet)
        }
    }

    Component {
        id: secure_funds_page
        SecureFundsPage {
            onAddWallet: stack_view.push(add_wallet_page)
            onUseDevice: stack_view.push(use_device_page)
            onWatchOnlyWallet: stack_view.push(watch_only_wallet_page)
        }
    }

    Component {
        id: add_wallet_page
        AddWalletPage {
            onNewWallet: {
                const mnemonic = WalletManager.generateMnemonic(12)
                stack_view.push(register_page, { mnemonic })
            }
            onRestoreWallet: stack_view.push(restore_wallet_page)
        }
    }

    Component {
        id: use_device_page
        UseDevicePage {
            onConnectJadeClicked: stack_view.push(connect_jade_page)
            onConnectLedgerClicked: stack_view.push(connect_ledger_page)
        }
    }

    Component {
        id: connect_jade_page
        ConnectJadePage {
            onDeviceSelected: (device) => stack_view.push(jade_page, { device, login: true })
            onQrmodeSelected: stack_view.push(qrmode_page)
        }
    }

    Component {
        id: connect_ledger_page
        ConnectLedgerPage {
            onDeviceSelected: (device) => stack_view.push(ledger_page, { device })
        }
    }

    Component {
        id: mnemonic_warnings_page
        MnemonicWarningsPage {
            padding: 60
            onAccepted: stack_view.push(mnemonic_backup_page)
        }
    }

    Component {
        id: mnemonic_backup_page
        MnemonicBackupPage {
            padding: 60
            onSelected: (mnemonic) => stack_view.push(mnemonic_check_page, { mnemonic })
        }
    }

    Component {
        id: mnemonic_check_page
        MnemonicCheckPage {
            padding: 60
            onChecked: (mnemonic) => stack_view.push(register_page, { mnemonic })
        }
    }

    Component {
        id: register_page
        RegisterPage {
            onRegisterFinished: (context) => {
                self.wallet = context.wallet
                stack_view.push(setup_pin_page, { context })
            }
        }
    }

    Component {
        id: setup_pin_page
        SetupPinPage {
            onFinished: (context) => stack_view.replace(null, loading_page, { context }, StackView.PushTransition)
            onCloseClicked: {
                self.closeWallet(self.wallet)
                WalletManager.removeWallet(self.wallet)
            }
        }
    }

    Component {
        id: restore_wallet_page
        RestorePage {
            onMnemonicEntered: (wallet, mnemonic, password) => stack_view.push(restore_check_page, { wallet, mnemonic, password })
            onRemoveClicked: self.removeWallet(self.wallet)
            onCloseClicked: self.closeWallet(self.wallet)
        }
    }

    Component {
        id: restore_check_page
        RestoreCheckPage {
            onRestoreFinished: (context) => {
                Settings.registerEvent({ walletId: context.xpubHashId, result: 'completed', type: 'wallet_backup' })
                self.wallet = context.wallet
                stack_view.push(setup_pin_page, { context })
            }
            onAlreadyRestored: (wallet) => stack_view.replace(already_restored_page, { wallet })
            onMismatch: stack_view.pop()
        }
    }

    Component {
        id: already_restored_page
        AlreadyRestoredPage {
            onOpenWallet: (wallet) => {
                self.openWallet(wallet)
                stack_view.replace(null, terms_of_service_page, {}, StackView.Immediate)
            }
            onCancel: stack_view.replace(null, terms_of_service_page, {}, StackView.PushTransition)
        }
    }

    Component {
        id: watch_only_wallet_page
        WatchOnlyWalletPage {
            onSinglesigWallet: stack_view.push(singlesig_watch_only_network_page)
            onMultisigWallet: stack_view.push(multisig_watch_only_network_page)
        }
    }

    Component {
        id: singlesig_watch_only_network_page
        WatchOnlyNetworkPage {
            electrum: true
            onNetworkSelected: (network) => stack_view.push(singlesig_watch_only_add_page, { network })
        }
    }

    Component {
        id: singlesig_watch_only_add_page
        SinglesigWatchOnlyAddPage {
            onLoginFinished: (context) => {
                self.wallet = context.wallet
                stack_view.replace(null, loading_page, { context }, StackView.PushTransition)
            }
        }
    }

    Component {
        id: multisig_watch_only_network_page
        WatchOnlyNetworkPage {
            electrum: false
            onNetworkSelected: (network) => stack_view.push(multisig_watch_only_add_page, { network })
        }
    }

    Component {
        id: multisig_watch_only_add_page
        MultisigWatchOnlyAddPage {
            onLoginFinished: (context) => {
                self.wallet = context.wallet
                stack_view.replace(null, loading_page, { context }, StackView.PushTransition)
            }
        }
    }

    Component {
        id: watch_only_login_page
        WatchOnlyLoginPage {
            onLoginFinished: (context) => {
                self.wallet = context.wallet
                stack_view.replace(null, loading_page, { context }, StackView.PushTransition)
            }
            onRemoveClicked: self.removeWallet(self.wallet)
            onCloseClicked: self.closeWallet(self.wallet)
        }
    }

    Component {
        id: pin_login_page
        PinLoginPage {
            onLoginFinished: (context) => {
                stack_view.replace(null, loading_page, { context }, StackView.PushTransition)
            }
            onRestoreClicked: stack_view.replace(restore_wallet_page, { wallet: self.wallet })
            onRemoveClicked: self.removeWallet(self.wallet)
            onCloseClicked: self.closeWallet(self.wallet)
        }
    }

    Component {
        id: loading_page
        LoadingPage {
            onLoadFinished: (context) => {
                stack_view.replace(null, overview_page, { context }, StackView.PushTransition)
            }
        }
    }

    Component {
        id: overview_page
        OverviewPage {
            Component.onDestruction: self.wallet.disconnect()
            onLogout: stack_view.replace(logout_page, StackView.PushTransition)
            onJadeDetailsClicked: self.openJadeDetailsDrawer()
        }
    }

    Component {
        id: logout_page
        StackViewPage {
            Timer {
                id: logout_timer
                interval: 500
                running: true
                repeat: true
                onTriggered: {
                    if (!self.wallet || !self.wallet.context) {
                        logout_timer.stop()
                        self.closeWallet(self.wallet)
                    }
                }
            }
            id: page
            padding: 60
            title: self.wallet?.name ?? ''
            contentItem: ColumnLayout {
                VSpacer {
                }
                BusyIndicator {
                    Layout.alignment: Qt.AlignCenter
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 22
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: qsTrId('id_logout')
                    wrapMode: Label.WordWrap
                }
                VSpacer {
                }
            }
        }
    }

    component JadeQRModePage: StackViewPage {
        JadeQRController {
            id: controller
            onHttpRequest: (request) => {
                const dialog = http_request_dialog.createObject(page, { request, context: self.context })
                dialog.open()
            }
            onResultEncoded: (result) => page.StackView.view.replace(parts_page, result, StackView.PushTransition)
        }
        id: page
        padding: 60
        title: qsTrId('id_scan_qr_code')
        contentItem: ColumnLayout {
            spacing: 20
            VSpacer {
            }
            ScannerView {
                Layout.alignment: Qt.AlignCenter
                Layout.minimumWidth: 350
                Layout.minimumHeight: 350
                onBcurScanned: (result) => controller.process(result)
            }
            VSpacer {
            }
        }
    }
    Component {
        id: parts_page
        StackViewPage {
            required property var parts
            padding: 60
            id: page
            title: qsTrId('id_scan_qr_code')
            contentItem: ColumnLayout {
                Slider {
                    id: slider
                    from: 0
                    stepSize: 1
                    to: page.parts.length - 1
                    visible: false
                }
                Timer {
                    interval: 250
                    running: true
                    repeat: true
                    onTriggered: slider.value = (slider.value + 1) % (slider.to + 1)
                }
                VSpacer {
                }
                QRCode {
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: 360
                    implicitHeight: 360
                    text: page.parts[Math.round(slider.value)].toUpperCase()
                }
                VSpacer {
                }
            }
            footerItem: RowLayout {
                HSpacer {
                }
                PrimaryButton {
                    Layout.minimumWidth: 350
                    text: qsTrId('id_done')
                    onClicked: page.StackView.view.pop()
                }
                HSpacer {
                }
            }
        }
    }
    Component {
        id: http_request_dialog
        JadeHttpRequestDialog {
        }
    }
    Component {
        id: jade_details_drawer
        JadeDetailsDrawer {
        }
    }
}
