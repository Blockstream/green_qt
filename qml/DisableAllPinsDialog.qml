import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    title: qsTrId('Disable All Pins')
    controller: Controller {
        wallet: dialog.wallet
    }
    width: 400
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                property bool destructive: true
                text: qsTrId('Disable All Pins')
                enabled: confirm_checkbox.checked
                onTriggered: {
                    controller.disableAllPins()
                    dialog.accept()
                }
            }
        ]
        Label {
            Layout.fillWidth: true
            text: qsTrId('This will prevent this wallet to be access by pin on any device. Mnemonic restore will be necessary to restore access to wallet.')
            wrapMode: Label.WordWrap
        }
        CheckBox {
            Layout.fillWidth: true
            id: confirm_checkbox
            text: qsTrId('I confirm I want to disable all pins access')
        }
    }
}
