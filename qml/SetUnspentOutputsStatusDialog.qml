import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    property var outputs
    property string status

    id: self
    title: qsTrId('id_set_unspent_outputs_status')
    doneText: qsTrId('id_disabled')

    controller: Controller {
        wallet: self.wallet
    }

    initialItem: RowLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_next')
                onTriggered: controller.setUnspentOutputsStatus(self.outputs, self.status)
            }
        ]
        spacing: constants.s1
    }
}
