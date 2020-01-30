import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import './views'

ControllerDialog {
    id: controller_dialog
    property string method
    initialText: 'Disable %1 Two-Factor Authentication'.arg(method) // TODO:translate
    doneText: qsTr('id_disabled')

    controller: TwoFactorController {
        method: controller_dialog.method
    }

    modal: true
    width: 400
    height: 300

    anchors.centerIn: parent

    initialItem: WizardPage {
        actions: Action {
            text: qsTr('id_next')
            onTriggered: controller.disable()
        }
        Label {
            text: initialText
        }
    }
}
