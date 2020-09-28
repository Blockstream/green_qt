import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    required property Wallet wallet
    title: qsTrId('id_set_an_email_for_recovery')
    controller: Controller {
        wallet: dialog.wallet
    }
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                enabled: email_field.text.trim() !== ''
                text: qsTrId('id_next')
                onTriggered: controller.setRecoveryEmail(email_field.text)
            }
        ]
        Label {
            text: qsTrId('id_set_up_an_email_to_get')
            wrapMode: Text.Wrap
            Layout.maximumWidth: 400
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        TextField {
            id: email_field
            Layout.fillWidth: true
            placeholderText: qsTrId('id_enter_your_email_address')
        }
    }
}
