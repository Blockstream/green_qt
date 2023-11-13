import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    signal openWallet(Wallet wallet)
    required property Wallet wallet

    Component.onCompleted: {
        if (!self.wallet) {
            stack_view.push(terms_of_service_page, {}, StackView.Immediate)
            return
        }

        if (self.wallet.context) {
            stack_view.push(loading_page, { context: self.wallet.context }, StackView.Immediate)
            return
        }

        stack_view.push(pin_login_page, { wallet: self.wallet }, StackView.Immediate)
    }

    id: self
    contentItem: GStackView {
        id: stack_view
        focus: true
        onCurrentItemChanged: stack_view.currentItem.forceActiveFocus()
    }

    Component {
        id: terms_of_service_page
        TermOfServicePage {
            onAddWallet: stack_view.push(add_wallet_page)
            onUseDevice: stack_view.push(use_device_page)
        }
    }

    Component {
        id: add_wallet_page
        AddWalletPage {
            onNewWallet: stack_view.push(mnemonic_warnings_page)
            onRestoreWallet: stack_view.push(restore_wallet_page)
            // TODO present singlesig or multisig options once singlesig watchonly login is implemented
            // onWatchOnlyWallet: stack_view.push(watch_only_wallet_page)
            onWatchOnlyWallet: stack_view.push(multisig_watch_only_network_page)
        }
    }

    Component {
        id: use_device_page
        UseDevicePage {
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
            onMnemonicEntered: (mnemonic, password) => stack_view.push(restore_check_page, { mnemonic, password })
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
                stack_view.replace(null, pin_login_page, { wallet: self.wallet })
            }
        }
    }
}
