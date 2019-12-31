import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'
import '../dialogs'

ColumnLayout {
    spacing: 30

    SettingsController {
        id: controller
    }

    SettingsBox {
        Layout.fillWidth: true

        title: qsTr('id_access')
        subtitle: qsTr('id_enable_or_change_your_pin_to')

        FlatButton {
            Component {
                id: change_pin_dialog
                ChangePinDialog {
                    modal: true
                    anchors.centerIn: parent
                }
            }

            text: qsTr('id_change_pin')
            onClicked: change_pin_dialog.createObject(Window.window).open()
        }

    }

    SettingsBox {
        title: qsTr('id_auto_logout_timeout')
        subtitle: qsTr('id_set_a_timeout_to_logout_after')

        ComboBox {
            model: [1, 2, 5, 10, 60]
            delegate: ItemDelegate {
                width: parent.width
                text: qsTr('id_1d_minutes').arg(modelData)
            }
            displayText: qsTr('id_1d_minutes').arg(currentText)
            onCurrentTextChanged: controller.change({ altimeout: model[currentIndex] })
            currentIndex: model.indexOf(wallet.settings.altimeout)
            Layout.fillWidth: true
        }
    }


    SettingsBox {
        title: qsTr('id_watchonly_login')
        subtitle: qsTr('id_set_up_watchonly_credentials')

        RowLayout {
            Switch {
                onCheckedChanged: credentials.visible = checked
            }

            ColumnLayout {

                id: credentials
                visible: false

                TextField {
                    placeholderText: qsTr('id_username')
                    padding: 10
                }

                TextField {
                    placeholderText: qsTr('id_password')
                    padding: 10
                }
            }
        }
    }

    SettingsBox {
        title: qsTr('id_wallet_backup')
        subtitle: qsTr('id_your_wallet_backup_is_made_of')

        RowLayout {
            Component {
                id: mnemonic_dialog
                MnemonicDialog {
                    anchors.centerIn: parent
                }
            }
            FlatButton {
                flat: true
                text: qsTr('id_mnemonic')
                onClicked: mnemonic_dialog.createObject(stack_view).open()
            }
        }
    }

    SettingsBox {
        title: qsTr('id_twofactor_authentication')
        subtitle: qsTr('id_enable_twofactor_authentication')

        ColumnLayout {
            Component {
                id: enable_dialog
                TwoFactorEnableDialog { }
            }
            Component {
                id: disable_dialog
                TwoFactorDisableDialog { }
            }
            Repeater {
                model: ['sms', 'phone', 'email', 'gauth']
                RowLayout {
                    property string method: modelData
                    Image {
                        source: `../assets/svg/2fa_${method}.svg`
                        sourceSize.height: 32
                    }
                    Label {
                        text: method.toUpperCase()
                        Layout.fillWidth: true
                    }
                    Button {
                        flat: true
                        text: qsTr('id_enable')
                        visible: !wallet.config[method].enabled
                        onClicked: enable_dialog.createObject(stack_view, { method }).open()
                    }
                    Button {
                        flat: true
                        text: qsTr('id_disable')
                        visible: wallet.config[method].enabled
                        onClicked: disable_dialog.createObject(stack_view, { method }).open()
                    }
                }
            }
        }
    }

    SettingsBox {
        title: 'nLockTime' // TODO: move to own recovery tab
        subtitle: 'nLockTime'
        ColumnLayout {
            FlatButton {
                text: qsTr('Show outputs expiring soon') // TODO: update
            }

            FlatButton {
                text: qsTr('id_request_recovery_transactions')
            }
        }
    }

    SettingsBox {
        title: qsTr('id_twofactor_authentication_expiry')
        subtitle: qsTr('id_select_duration_of_twofactor')
        ComboBox {
            currentIndex: 1
            model: ListModel {
                id: csvComboBox
                ListElement { text: "4320" }
                ListElement { text: "25920" }
                ListElement { text: "51840" }
                ListElement { text: "65535" }
            }
            width: 200
            padding: 10
        }
    }

    SettingsBox {
        title: qsTr('id_set_twofactor_threshold')
        subtitle: qsTr('id_set_a_limit_to_spend_without')

        RowLayout {
            Item {
                Layout.fillWidth: true
            }
            Button {
                property Component dialog: TwoFactorLimitDialog {}
                flat: true
                text: qsTr('id_set_twofactor_threshold')
                onClicked: dialog.createObject(stack_view).open()
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    SettingsBox {
        title: qsTr('id_set_an_email_for_recovery')
        subtitle: qsTr('id_providing_an_email_enables')

        TextField {
            placeholderText: 'blabla@gmail.com'
        }
    }

    SettingsBox {
        title: qsTr('id_request_twofactor_reset')
        subtitle: qsTr('id_start_a_2fa_reset_process_if')

        RowLayout {
            TextField {
                placeholderText: qsTr('id_enter_new_email')
                padding: 10
            }

            FlatButton {
                text: qsTr('id_reset')
                padding: 10
            }
        }
    }
}
