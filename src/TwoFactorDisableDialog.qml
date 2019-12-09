import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import './views'

ControllerDialog {
    id: controller_dialog
    property string method

    controller: TwoFactorController {
        method: controller_dialog.method
    }

    modal: true
    width: 400
    height: 300

    anchors.centerIn: parent

    initialItem: WizardPage {
        actions: Action {
            text: 'NEXT'
            onTriggered: controller.disable()
        }
        Label {
            text: 'ARE YOU SURE?'
        }
    }
}
