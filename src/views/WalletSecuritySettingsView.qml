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

        title: 'Quick login'
        subtitle: 'Enable a PIN to quickly access your wallet for this device'

        FlatButton {
            Component {
                id: change_pin_dialog
                ChangePinDialog {
                    modal: true
                    anchors.centerIn: parent
                }
            }

            text: qsTr('Change PIN')
            onClicked: change_pin_dialog.createObject(Window.window).open()
        }

    }

    SettingsBox {
        title: 'Autologout'
        subtitle: 'Configure autologout after some inactivity'

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
        title: 'Enable watch-only login'
        subtitle: 'Allow watch-only login to your wallet'

        RowLayout {
            Switch {
                onCheckedChanged: credentials.visible = checked
            }

            ColumnLayout {

                id: credentials
                visible: false

                TextField {
                    placeholderText: qsTr('Username')
                    padding: 10
                }

                TextField {
                    placeholderText: qsTr('Password')
                    padding: 10
                }
            }
        }
    }

    SettingsBox {
        title: 'Show mnemonic'
        subtitle: 'Display your mnemonic'

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
        title: 'Two factor auth'
        subtitle: 'Set any or all two factor: you can choose which one when needed! Enable two or back up the given code when applicable'

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
        title: 'nLockTime'
        subtitle: 'nLockTime'
        ColumnLayout {
            FlatButton {
                text: qsTr('Show outputs expiring soon')
            }

            FlatButton {
                text: qsTr('Send all nLockTime transactions by email')
            }
        }
    }

    SettingsBox {
        title: 'CSV value'
        subtitle: 'CSV value'
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
        title: 'Limit currency'
        subtitle: 'Set some limits for which you won\'t be asked for 2FA'

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
        title: 'Email'
        subtitle: 'Set your email address for transactions notifications, two factor authentication and nLocktime transaction'

        TextField {
            placeholderText: 'blabla@gmail.com'
        }
    }

    SettingsBox {
        title: 'Reset 2FA'
        subtitle: 'If you have lost access to your 2FA mechanisms you can start the 2FA recovery process. WARNING: Starting the reset process will lock your wallet'

        RowLayout {
            TextField {
                placeholderText: qsTr('Recovery email')
                padding: 10
            }

            FlatButton {
                text: qsTr('Request 2FA reset')
                padding: 10
            }
        }
    }
}
