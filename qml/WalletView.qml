import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    signal openWallet(Wallet wallet)
    property Wallet wallet
    property Device device
    Component.onCompleted: {
        if (!self.wallet) {
            if (self.device instanceof JadeDevice) {
                stack_view.push(jade_page, { device: self.device }, StackView.Immediate)
            } else {
                stack_view.push(terms_of_service_page, {}, StackView.Immediate)
            }
        } else if (self.wallet.context) {
            stack_view.push(loading_page, { context: self.wallet.context }, StackView.Immediate)
        } else {
            stack_view.push(pin_login_page, { wallet: self.wallet }, StackView.Immediate)
        }
    }
    id: self
    contentItem: GStackView {
        id: stack_view
        focus: true
    }

    Component {
        id: jade_page
        JadePage {
            onLoginFinished: (context) => {
                self.wallet = context.wallet
                stack_view.push(loading_page, { context })
            }
        }
    }

    Component {
        id: terms_of_service_page
        TermOfServicePage {
            onAddWallet: (deployment) => stack_view.push(add_wallet_page, { deployment })
            onUseDevice: (deployment) => stack_view.push(use_device_page, { deployment })
        }
    }

    Component {
        id: add_wallet_page
        AddWalletPage {
            onNewWallet: (deployment) => stack_view.push(mnemonic_warnings_page, { deployment })
            onRestoreWallet: (deployment) => stack_view.push(restore_wallet_page, { deployment })
            // TODO present singlesig or multisig options once singlesig watchonly login is implemented
            // onWatchOnlyWallet: stack_view.push(watch_only_wallet_page)
            onWatchOnlyWallet: (deployment) => stack_view.push(multisig_watch_only_network_page, { deployment })
        }
    }

    Component {
        id: use_device_page
        UseDevicePage {
            onConnectJadeClicked: (deployment) => stack_view.push(connect_jade_page, { deployment })
        }
    }

    Component {
        id: connect_jade_page
        ConnectJadePage {
            onDeviceSelected: (deployment, device) => stack_view.push(jade_page, { deployment, device })
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
        }
    }

    Component {
        id: restore_wallet_page
        RestorePage {
            onMnemonicEntered: (deployment, mnemonic, password) => stack_view.push(restore_check_page, { deployment, mnemonic, password })
        }
    }

    Component {
        id: restore_check_page
        RestoreCheckPage {
            onRestoreFinished: (context) => {
               self.wallet = context.wallet
               stack_view.push(setup_pin_page, { context })
            }
            onAlreadyRestored: (wallet) => stack_view.replace(already_restored_page, { wallet })
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
            onMultisigWallet: stack_view.push(multisig_watch_only_network_page)
        }
    }

    Component {
        id: multisig_watch_only_network_page
        MultisigWatchOnlyNetworkPage {
            onNetworkSelected: (network) => stack_view.push(multisig_watch_only_login_page, { network })
        }
    }

    Component {
        id: multisig_watch_only_login_page
        MultisigWatchOnlyLoginPage {
            onLoginFinished: (context) => {
                self.wallet = context.wallet
                stack_view.push(loading_page, { context })
            }
        }
    }

    Component {
        id: pin_login_page
        PinLoginPage {
            onLoginFinished: (context) => {
                stack_view.push(loading_page, { context })
            }
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
            onLogout: {
                if (!self.wallet) {
                    stack_view.replace(null, terms_of_service_page, {}, StackView.PushTransition)
                    return
                }
                if (self.wallet.hasPinData) {
                    stack_view.replace(null, pin_login_page, { wallet: self.wallet })
                    return
                }
                if (self.wallet?.context?.device instanceof JadeDevice) {
                    stack_view.replace(null, jade_page, { device: self.wallet?.context?.device })
                    return
                }

                console.log('missing logout view')
            }
        }
    }
}
