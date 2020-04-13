import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    title: qsTr('id_set_an_email_for_recovery')
    controller: SetRecoveryEmailController { }
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                enabled: email_field.text.trim() !== ''
                text: qsTr('id_next')
                onTriggered: controller.execute(email_field.text)
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
            placeholderText: qsTr('id_enter_your_email_address')
        }
    }
}
