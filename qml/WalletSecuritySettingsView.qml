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
        title: qsTrId('id_access')
        visible: !wallet.device
        contentItem: ColumnLayout {
            Label {
                text: qsTrId('id_enable_or_change_your_pin_to')
                wrapMode: Label.WordWrap
            }
            Button {
                Layout.alignment: Qt.AlignRight
                Component {
                    id: change_pin_dialog
                    ChangePinDialog {
                        modal: true
                        anchors.centerIn: parent
                    }
                }
                flat: true
                text: qsTrId('id_change_pin')
                onClicked: change_pin_dialog.createObject(Window.window).open()
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_auto_logout_timeout')
        enabled: !wallet.locked
        visible: !wallet.device
        contentItem: ColumnLayout {
            Label {
                wrapMode: Label.WordWrap
                text: qsTrId('id_set_a_timeout_to_logout_after')
            }
            ComboBox {
                Layout.alignment: Qt.AlignRight
                flat: true
                model: [1, 2, 5, 10, 60]
                width: 200
                delegate: ItemDelegate {
                    width: parent.width
                    text: qsTrId('id_1d_minutes').arg(modelData)
                }
                displayText: qsTrId('id_1d_minutes').arg(currentText)
                onCurrentTextChanged: controller.changeSettings({ altimeout: model[currentIndex] })
                currentIndex: model.indexOf(wallet.settings.altimeout)
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_twofactor_authentication')
        enabled: !wallet.locked
        contentItem: ColumnLayout {
            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                text: qsTrId('id_enable_twofactor_authentication')
                wrapMode: Label.WordWrap
                Layout.minimumWidth: 0 //contentWidth
            }
            Repeater {
                model: wallet.config.all_methods || []

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    property string method: modelData

                    Image {
                        source: `qrc:/svg/2fa_${method}.svg`
                        sourceSize.height: 32
                    }
                    Label {
                        text: method.toUpperCase()
                        Layout.minimumWidth: 64
                    }
                    Switch {
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
        contentItem: ColumnLayout {
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0 //contentWidth
                text: qsTrId('id_set_a_limit_to_spend_without')
            }
            Button {
                property Component dialog: TwoFactorLimitDialog {
                    wallet: self.wallet
                }
                flat: true
                text: qsTrId('id_set_twofactor_threshold')
                onClicked: dialog.createObject(stack_view).open()
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_twofactor_authentication_expiry')
        visible: !wallet.network.liquid
        contentItem: ColumnLayout {
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_customize_2fa_expiration_of')
                wrapMode: Label.WordWrap
            }
            Button {
                Layout.alignment: Qt.AlignRight
                flat: true
                text: qsTrId('id_set_2fa_expiry')
                onClicked: two_factor_auth_expiry_dialog.createObject(stack_view).open()
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_request_twofactor_reset')
        visible: !wallet.network.liquid
        contentItem: ColumnLayout {
            Label {
                Layout.fillWidth: true
                text: wallet.locked ? qsTrId('wallet locked for %1 days').arg(wallet.config.twofactor_reset ? wallet.config.twofactor_reset.days_remaining : 0) : qsTrId('id_start_a_2fa_reset_process_if')
                wrapMode: Label.WordWrap
            }
            Button {
                flat: true
                Layout.alignment: Qt.AlignRight
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
        id: two_factor_auth_expiry_dialog
        TwoFactorAuthExpiryDialog {
            wallet: self.wallet
        }
    }
}
