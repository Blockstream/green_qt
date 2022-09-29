import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    id: self
    required property Wallet wallet

    spacing: 16

    Controller {
        id: controller
        wallet: self.wallet
    }

    SettingsBox {
        title: qsTrId('id_twofactor_authentication')
        enabled: !wallet.locked
        contentItem: ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_enable_twofactor_authentication')
                wrapMode: Text.WordWrap
            }
            Repeater {
                model: {
                    const methods = wallet.config.all_methods || []
                    return methods.filter(method => {
                        switch (method) {
                            case 'email': return true
                            case 'sms': return true
                            case 'phone': return true
                            case 'gauth': return true
                            case 'telegram': return true
                            default: return false
                        }
                    })
                }

                RowLayout {
                    Layout.fillWidth: true

                    property string method: modelData

                    Image {
                        source: `qrc:/svg/2fa_${method}.svg`
                        sourceSize.height: 32
                    }
                    ColumnLayout {
                        Label {
                            text: {
                                switch(method) {
                                    case 'email':
                                        return qsTrId('id_email')
                                    case 'sms':
                                        return qsTrId('id_sms')
                                    case 'phone':
                                        return qsTrId('id_phone_call')
                                    case 'gauth':
                                        return qsTrId('id_authenticator_app')
                                    case 'telegram':
                                        return qsTrId('id_telegram')
                                }
                            }
                        }
                        Label {
                            visible: wallet.config[method].enabled
                            text: method === 'gauth' ? qsTrId('id_enabled') : wallet.config[method].data
                            color: constants.c100
                            font.pixelSize: 10
                        }
                    }
                    HSpacer {
                    }
                    GSwitch {
                        Binding on checked {
                            value: wallet.config[method].enabled
                        }

                        onClicked: {
                            checked = wallet.config[modelData].enabled;
                            if (!wallet.config[method].enabled) {
                                enable_dialog.createObject(stack_view, { method }).open();
                            } else {
                                disable_dialog.createObject(stack_view, { method }).open();
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_set_twofactor_threshold')
        enabled: !wallet.locked
        visible: !wallet.network.liquid
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: qsTrId('id_set_a_limit_to_spend_without')
                wrapMode: Text.WordWrap
            }
            GButton {
                large: false
                text: qsTrId('id_change')
                onClicked: set_twofactor_threshold_dialog.createObject(stack_view).open()
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_twofactor_authentication_expiry')
        visible: !wallet.network.liquid
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_customize_2fa_expiration_of')
                wrapMode: Text.WordWrap
            }
            GButton {
                Layout.alignment: Qt.AlignRight
                large: false
                text: qsTrId('id_change')
                onClicked: two_factor_auth_expiry_dialog.createObject(stack_view).open()
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_request_twofactor_reset')
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                text: wallet.locked ? qsTrId('wallet locked for %1 days').arg(wallet.config.twofactor_reset ? wallet.config.twofactor_reset.days_remaining : 0) : qsTrId('id_start_a_2fa_reset_process_if')
                wrapMode: Text.WordWrap
            }
            GButton {
                large: false
                Layout.alignment: Qt.AlignRight
                enabled: wallet.config.any_enabled || false
                text: wallet.locked ? qsTrId('id_cancel_twofactor_reset') : qsTrId('id_reset')
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
                        cancel_dialog.createObject(stack_view, { wallet }).open()
                    } else {
                        request_dialog.createObject(stack_view, { wallet }).open()
                    }
                }
            }
        }
    }

    Component {
        id: enable_dialog
        TwoFactorEnableDialog {
            wallet: self.wallet
            description: switch(method) {
                case 'sms':
                    return qsTrId('id_enter_phone_number')
                case 'gauth':
                    return qsTrId('id_scan_the_qr_code_in_google')
                case 'email':
                    return qsTrId('id_enter_your_email_address')
                case 'phone':
                    return qsTrId('id_enter_phone_number')
                case 'telegram':
                    return qsTrId('id_enter_telegram_username_or_number')
            }
        }
    }

    Component {
        id: disable_dialog
        TwoFactorDisableDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: set_twofactor_threshold_dialog
        TwoFactorLimitDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: two_factor_auth_expiry_dialog
        TwoFactorAuthExpiryDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: change_pin_dialog
        ChangePinDialog {
            wallet: self.wallet
        }
    }

    Component {
        id: disable_all_pins_dialog
        DisableAllPinsDialog {
            wallet: self.wallet
        }
    }
}
