import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    id: self

    Image {
        parent: self.background
        source: 'qrc:/svg2/onboard_background.svg'
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    GStackView {
        id: stack_view
        anchors.fill: parent
        anchors.margins: 60
        focus: true
        initialItem: TermOfServicePage {
            onAddWallet: stack_view.push(add_wallet_page)
        }
        onCurrentItemChanged: stack_view.currentItem.forceActiveFocus()
    }

    Component {
        id: add_wallet_page
        AddWalletPage {
            onNewWallet: stack_view.push(mnemonic_warnings_page)
            onRestoreWallet: stack_view.push(restore_wallet_page)
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
        StackViewPage {
            required property string pin
            required property var mnemonic
            id: self
            leftItem: null
            StackView.onActivated: controller.active = true
            SignupController {
                id: controller
                pin: self.pin
                mnemonic: self.mnemonic
                network: NetworkManager.network('electrum-mainnet')
                onWalletChanged: {
                    navigation.set({ view: 'wallets', wallet: controller.wallet.id })
                    stack_view.pop(stack_view.initialItem)
                }
            }
            contentItem: ColumnLayout {
                VSpacer {
                }
                BusyIndicator {
                    Layout.alignment: Qt.AlignCenter
                    running: !controller.wallet
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: restore_wallet_page
        StackViewPage {
        }
    }
}
