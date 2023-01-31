import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ColumnLayout {
    required property Wallet wallet

    id: self
    spacing: 16

    AnalyticsView {
        active: true
        name: 'WalletSettingsRecovery'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    SettingsBox {
        title: qsTrId('id_recovery_phrase')
        visible: !wallet.device
        contentItem: ColumnLayout {
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_the_recovery_phrase_can_be_used') + ' ' + qsTrId('id_blockstream_does_not_have')
                wrapMode: Text.WordWrap
            }
            GButton {
                Layout.alignment: Qt.AlignRight
                large: false
                text: qsTrId('id_show')
                onClicked: mnemonic_dialog.createObject(stack_view).open()
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !self.wallet.network.electrum
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_accounts_summary')
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_save_a_summary_of_your_accounts')
                    wrapMode: Text.WordWrap
                }
                GButton {
                    Layout.alignment: Qt.AlignRight
                    text: qsTrId('id_copy')
                    large: false
                    onClicked: {
                        const subaccounts = [];
                        for (let i = 0; i < wallet.accounts.length; i++) {
                            const data = wallet.accounts[i].json;
                            const subaccount = { type: data.type, pointer: data.pointer };
                            if (data.type === '2of3') subaccount.recovery_pub_key = data.recovery_pub_key;
                            subaccounts.push(subaccount)
                        }
                        Clipboard.copy(JSON.stringify({ subaccounts }, null, '  '))
                        ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
                    }
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !self.wallet.network.electrum && !wallet.network.liquid
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_set_timelock')
            enabled: !!wallet.settings.notifications &&
                     !!wallet.settings.notifications.email_incoming &&
                     !!wallet.settings.notifications.email_outgoing
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_redeem_your_deposited_funds') + '\n\n' + qsTrId('id_enable_email_notifications_to')
                    wrapMode: Text.WordWrap
                }
                GButton {
                    Layout.alignment: Qt.AlignRight
                    large: false
                    text: qsTrId('id_set_timelock')
                    onClicked: nlocktime_dialog.createObject(stack_view).open()
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !self.wallet.network.electrum && !wallet.network.liquid
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_set_an_email_for_recovery')            
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_set_up_an_email_to_get')
                    wrapMode: Text.WordWrap
                }
                GButton {
                    Layout.alignment: Qt.AlignRight
                    Component {
                        id: enable_dialog
                        SetRecoveryEmailDialog {
                            wallet: self.wallet
                        }
                    }
                    large: false
                    enabled: !wallet.config.email || !wallet.config.email.confirmed
                    text: qsTrId('id_enable')
                    onClicked: enable_dialog.createObject(stack_view).open()
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !self.wallet.network.electrum
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_delete_wallet')
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_delete_permanently_your_wallet')
                    wrapMode: Text.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    visible: !self.wallet.empty
                    text: qsTrId('id_all_of_the_accounts_in_your')
                    wrapMode: Text.WordWrap
                }
                GButton {
                    Layout.alignment: Qt.AlignRight
                    large: false
                    destructive: true
                    enabled: self.wallet.empty
                    text: qsTrId('id_delete_wallet')
                    onClicked: delete_wallet_dialog.createObject(self).open()
                }
            }
        }
    }

    Component {
        id: mnemonic_dialog
        MnemonicDialog {
            anchors.centerIn: parent
            wallet: self.wallet
        }
    }

    Component {
        id: nlocktime_dialog
        NLockTimeDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: delete_wallet_dialog
        DeleteWalletDialog {
            wallet: self.wallet
        }
    }
}
