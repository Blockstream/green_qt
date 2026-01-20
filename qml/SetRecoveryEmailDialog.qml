import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: self
    objectName: "SetRecoveryEmailDialog"
    title: qsTrId('id_set_an_email_for_recovery')
    controller: Controller {
        context: self.wallet.context
    }
    ColumnLayout {
        Label {
            text: qsTrId('id_set_up_an_email_to_get')
            wrapMode: Text.Wrap
            Layout.maximumWidth: 400
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        GTextField {
            id: email_field
            Layout.fillWidth: true
            placeholderText: qsTrId('id_enter_your_email_address')
        }
        GButton {
            enabled: email_field.text.trim() !== ''
            text: qsTrId('id_next')
            onClicked: controller.setRecoveryEmail(email_field.text)
        }
    }
}
