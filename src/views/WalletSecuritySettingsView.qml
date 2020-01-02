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
        description: qsTr('id_enable_or_change_your_pin_to')

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
        description: qsTr('id_set_a_timeout_to_logout_after')

        ComboBox {
            model: [1, 2, 5, 10, 60]
            width: 200
            delegate: ItemDelegate {
                width: parent.width
                text: qsTr('id_1d_minutes').arg(modelData)
            }
            displayText: qsTr('id_1d_minutes').arg(currentText)
            onCurrentTextChanged: controller.change({ altimeout: model[currentIndex] })
            currentIndex: model.indexOf(wallet.settings.altimeout)
        }
    }


    /*SettingsBox {
        title: qsTr('id_watchonly_login')
        description: qsTr('id_set_up_credentials_to_access_in')

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
    }*/

    SettingsBox {
        title: qsTr('id_wallet_backup')
        description: qsTr('id_your_wallet_backup_is_made_of') + "\n" + qsTr('id_blockstream_does_not_have')

        RowLayout {
            Layout.fillWidth: true

            Component {
                id: mnemonic_dialog
                MnemonicDialog {
                    anchors.centerIn: parent
                }
            }
            FlatButton {
                Layout.alignment: Qt.AlignRight
                flat: true
                text: qsTr('id_show_my_wallet_backup')
                onClicked: mnemonic_dialog.createObject(stack_view).open()
            }
        }
    }

    SettingsBox {
        title: qsTr('id_twofactor_authentication')
        description: qsTr('id_enable_twofactor_authentication')

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
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    property string method: modelData

                    Image {
                        source: `../assets/svg/2fa_${method}.svg`
                        sourceSize.height: 32
                    }
                    Label {
                        text: method.toUpperCase()
                    }
                    Button {
                        flat: true
                        text: wallet.config[method].enabled ? qsTr('id_disable') : qsTr('id_enable')
                        onClicked: {
                            if (!wallet.config[method].enabled)
                                enable_dialog.createObject(stack_view, { method }).open()
                            else
                                disable_dialog.createObject(stack_view, { method }).open()
                        }
                    }
                }
            }
        }
    }


    SettingsBox {
        title: qsTr('id_twofactor_authentication_expiry')
        description: qsTr('id_select_duration_of_twofactor')
        ComboBox {
            Layout.alignment: Qt.AlignRight
            currentIndex: 1
            model: ListModel {
                id: csvComboBox
                ListElement { text: "4320" }
                ListElement { text: "25920" }
                ListElement { text: "51840" }
                ListElement { text: "65535" }
            }
            width: 200
            //padding: 10
        }
    }

    SettingsBox {
        title: qsTr('id_set_twofactor_threshold')
        description: qsTr('id_set_a_limit_to_spend_without')

        RowLayout {
            Layout.alignment: Qt.AlignRight
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


}
