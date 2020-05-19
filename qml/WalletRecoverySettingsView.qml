import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    property string title: qsTrId('id_recovery')

    spacing: 30

    SettingsController {
        id: controller
    }

    SettingsBox {
        title: qsTrId('id_wallet_backup')
        description: qsTrId('id_your_wallet_backup_is_made_of') + "\n" + qsTrId('id_blockstream_does_not_have')

        RowLayout {
            Layout.fillWidth: true

            Component {
                id: mnemonic_dialog
                MnemonicDialog {
                    anchors.centerIn: parent
                }
            }
            Button {
                Layout.alignment: Qt.AlignRight
                flat: true
                text: qsTrId('id_show_my_wallet_backup')
                onClicked: mnemonic_dialog.createObject(stack_view).open()
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_set_locktime')
        description: qsTrId('id_redeem_your_deposited_funds') + '\n\n' + qsTrId('id_enable_email_notifications_to')
        visible: !wallet.network.liquid
        enabled: wallet.settings.notifications &&
                 wallet.settings.notifications.email_incoming &&
                 wallet.settings.notifications.email_outgoing
        Button {
            Component {
                id: nlocktime_dialog
                NLockTimeDialog {}
            }
            flat: true
            text: qsTrId('id_set_locktime')
            onClicked: nlocktime_dialog.createObject(stack_view).open()
        }
    }

    SettingsBox {
        title: qsTrId('id_set_an_email_for_recovery')
        visible: !wallet.network.liquid
        Button {
            Component {
                id: enable_dialog
                SetRecoveryEmailDialog { }
            }

            flat: true
            enabled: !wallet.config['email'].confirmed
            text: qsTrId('id_enable')
            onClicked: enable_dialog.createObject(stack_view).open()
        }
    }

    SettingsBox {
        title: qsTrId('id_request_twofactor_reset')
        description: wallet.locked ? qsTrId('wallet locked for %1 days').arg(wallet.config.twofactor_reset.days_remaining) : qsTrId('id_start_a_2fa_reset_process_if')
        visible: !wallet.network.liquid
        RowLayout {
            Button {
                flat: true
                enabled: wallet.config.any_enabled || false
                text: wallet.locked ? qsTrId('id_cancel_twofactor_reset') : qsTrId('id_reset')
                padding: 10
                Component {
                    id: cancel_dialog
                    CancelTwoFactorResetDialog { }
                }

                Component {
                    id: request_dialog
                    RequestTwoFactorResetDialog { }
                }
                onClicked: {
                    if (wallet.locked) {
                        cancel_dialog.createObject(stack_view).open()
                    } else {
                        request_dialog.createObject(stack_view).open()
                    }
                }
            }
        }
    }

}
