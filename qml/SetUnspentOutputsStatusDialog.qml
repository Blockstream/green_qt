import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    required property var model
    required property var outputs
    required property string status

    id: self
    title: status === 'default' ? qsTrId('id_unlocking_coins') : qsTrId('id_locking_coins')
    doneText: status === 'default' ? qsTrId('id_coins_unlocked') : qsTrId('id_coins_locked')

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
                    return qsTrId('id_unlocked_coins_can_be_spent_and')
                }
                if (status=="frozen") {
                    return qsTrId('id_locked_coins_will_not_be_spent')
                }
            }
        }

        spacing: constants.s1
    }
}
