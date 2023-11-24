import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    required property Account account
    required property var model
    required property var outputs
    required property string status

    context: self.account.context

    id: self
    title: status === 'default' ? qsTrId('id_unlocking_coins') : qsTrId('id_locking_coins')
    // TODO
    // doneText: status === 'default' ? qsTrId('id_coins_unlocked') : qsTrId('id_coins_locked')

    controller: Controller {
        id: controller
        context: self.context
        onFinished: {
            self.model.fetch()
            self.accept()
        }
    }

    ColumnLayout {
        spacing: constants.s1

        Label {
            Layout.fillWidth: true
            text: {
                if (status === 'default') {
                    return qsTrId('id_unlocked_coins_can_be_spent_and')
                }
                if (status === 'frozen') {
                    return qsTrId('id_locked_coins_will_not_be_spent')
                }
            }
        }

        GButton {
            Layout.alignment: Qt.AlignCenter
            highlighted: true
            text: qsTrId('id_next')
            onClicked: controller.setUnspentOutputsStatus(self.account, self.outputs, self.status)
        }
    }
}
