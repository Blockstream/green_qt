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
        title: 'nLockTime' // TODO: move to own recovery tab
        ColumnLayout {
            Layout.alignment: Qt.AlignRight
            FlatButton {
                text: qsTr('Show outputs expiring soon') // TODO: update
            }

            FlatButton {
                text: qsTr('id_request_recovery_transactions')
            }
        }
    }

    SettingsBox {
        title: qsTr('id_set_an_email_for_recovery')
        description: qsTr('id_providing_an_email_enables')

        TextField {
            placeholderText: 'blabla@gmail.com'
        }
    }

    SettingsBox {
        title: qsTr('id_request_twofactor_reset')
        description: qsTr('id_start_a_2fa_reset_process_if')

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
