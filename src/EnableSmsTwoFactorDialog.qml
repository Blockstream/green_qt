import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import './views'

ControllerDialog {
    title: 'ENABLE TWO FACTOR SMS'

    controller: TwoFactorController {
        method: 'sms'
    }

    initialItem: WizardPage {
        actions: Action {
            text: qsTr('id_next')
            onTriggered: controller.enable(number_field.text)
        }
        TextField {
            placeholderText: 'phone number'
            id: number_field
        }
    }
}
