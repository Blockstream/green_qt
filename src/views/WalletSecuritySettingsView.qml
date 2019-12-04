import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

ColumnLayout {
    spacing: 30

    SettingsBox {
        title: 'Quick login'
        subtitle: 'Enable a PIN to quickly access your wallet for this device'

        FlatButton {
            text: qsTr('Change PIN')
        }

    }

    SettingsBox {
        title: 'Autologout'
        subtitle: 'Configure autologout after some inactivity'

        RowLayout {
            TextField {
                placeholderText: wallet.settings.altimeout
                padding: 10
            }

            Label {
                text: qsTr('Minutes')
                padding: 5
            }
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
            FlatButton {
                id: ddd
                checkable: true
                text: qsTr('SHOW MNEMONIC')
            }
            ProgressBar {
                visible: ddd.checked
                NumberAnimation on value {
                    id: caralho
                    duration: 15000
                    from: 1
                    to: 0
                    loops: 1
                    running: ddd.checked
                    onFinished: ddd.checked = false
                }
            }
        }

        MnemonicView {
            Layout.fillWidth: true
            Layout.minimumHeight: 300

            visible: ddd.checked
            mnemonic: wallet.mnemonic
        }
    }

    SettingsBox {
        title: 'Two factor auth'
        subtitle: 'Set any or all two factor: you can choose which one when needed! Enable two or back up the given code when applicable'

        GridLayout {
            columns: 2
            Label {
                text: 'sms'
            }
            Switch {
                onCheckedChanged: {
                    if (checked) {
                        two_factor_sms_enable_dialog.createObject(stack_view).open()
                    } else {
                        two_factor_sms_disable_dialog.createObject(stack_view).open()
                    }
                }
            }

            Label {
                text: 'call'
            }
            Switch { }

            Label {
                text: 'Gauth'
            }
            Switch { }

            Label {
                text: 'email'
            }
            Switch { }
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
            Label {
                text: qsTr('Total')
                padding: 10
            }

            TextField {
                text: qsTr('0')
                padding: 10
            }
            Label {
                text: qsTr('BTC')
                padding: 10
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

    /*

    TextField {
            id: code
            placeholderText: 'SMS CODE'
            visible: false
        }

        FlatButton {
            visible: code.visible
            text: 'VERIFY CODE'
            onClicked: ctrl.resolveCode(code.text)
        }

        FlatButton {
            text: 'ENABLE 2F SMS'
            TwoFactorController {
                id: ctrl
                wallet: foo
                onPromptCode: code.visible = true
            }
            onClicked: ctrl.go()
        }
        FlatButton {
            text: 'ENABLE 2F EMAIL'
            onClicked: ctrl.enableEmail()
        }

        FlatButton {
            text: 'DISABLE 2F SMS'
            onClicked: ctrl.disable();
        }
    */

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
