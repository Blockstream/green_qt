import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    required property Wallet wallet

    id: self

    Component.onCompleted: {
        if (!self.wallet) {
            stack_view.push(terms_of_service_page, {}, StackView.Immediate)
            return
        }

        if (self.wallet.context) {
            stack_view.push(loading_page, { context: self.wallet.context }, StackView.Immediate)
            return
        }

        stack_view.push(pin_login_page, {}, StackView.Immediate)
    }

    contentItem: GStackView {
        id: stack_view
        focus: true
        onCurrentItemChanged: stack_view.currentItem.forceActiveFocus()
    }

    Component {
        id: terms_of_service_page
        TermOfServicePage {
            onAddWallet: stack_view.push(add_wallet_page)
        }
    }

    Component {
        id: add_wallet_page
        AddWalletPage {
            onNewWallet: stack_view.push(mnemonic_warnings_page)
            onRestoreWallet: stack_view.push(restore_wallet_page)
            onWatchOnlyWallet: stack_view.push(watch_only_wallet_page)
        }
    }

    Component {
        id: mnemonic_warnings_page
        MnemonicWarningsPage {
            onAccepted: stack_view.push(mnemonic_backup_page)
        }
    }

    Component {
        id: mnemonic_backup_page
        MnemonicBackupPage {
            //onSelected: (mnemonic) => stack_view.push(setup_pin_page, { mnemonic })
            onSelected: (mnemonic) => stack_view.push(mnemonic_check_page, { mnemonic })
        }
    }

    Component {
        id: mnemonic_check_page
        MnemonicCheckPage {
            onChecked: (mnemonic) => stack_view.push(setup_pin_page, { mnemonic })
        }
    }

    Component {
        id: setup_pin_page
        SetupPinPage {
            onPinEntered: (pin) => stack_view.push(register_page, { pin, mnemonic })
        }
    }

    Component {
        id: register_page
        RegisterPage {
            onRegisterFinished: (context) => {
                self.wallet = context.wallet
                stack_view.push(loading_page, { context })
            }
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
        }
    }

    Component {
        id: watch_only_wallet_page
        WatchOnlyWalletPage {
            onMultisigWallet: stack_view.push(multisig_watch_only_login_page)
        }
    }

    Component {
        id: multisig_watch_only_login_page
        MultisigWatchOnlyLoginPage {
            onLoginFinished: (context) => {
                stack_view.push(loading_page, { context })
            }
        }
    }

    Component {
        id: pin_login_page
        PinLoginPage {
            wallet: self.wallet
            onLoginFinished: (context) => {
                stack_view.push(loading_page, { context })
            }
        }
    }

    Component {
        id: loading_page
        LoadingPage {
            onLoadFinished: (context) => {
                stack_view.push(overview_page, { context })
            }
        }
    }

    Component {
        id: overview_page
        OverviewPage {
            // StackView.onDeactivated: self.wallet.disconnect()
            onLogoutClicked: {
                stack_view.pop(null)
            }
        }
    }
}
