import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    required property var model
    required property var outputs
    required property string status

    id: self
    title: qsTrId('id_set_unspent_outputs_status')
    doneText: qsTrId('id_done')

    controller: Controller {
        wallet: self.wallet
        onFinished: self.model.fetch()
    }

    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_next')
                onTriggered: controller.setUnspentOutputsStatus(self.outputs, self.status)
            }
        ]
        Label {
            text: {
                if (status=="default") {
                    return qsTrId('UNLOCK COINS STRINGS')
                }
                if (status=="frozen") {
                    return qsTrId('LOCK COINS STRINGS')
                }
            }
        }

        spacing: constants.s1
    }
}
