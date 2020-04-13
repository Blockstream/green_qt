import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    title: qsTrId('id_cancel_twofactor_reset')
    controller: CancelTwoFactorResetController { }
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_next')
                onTriggered: controller.execute()
            }
        ]
        Label {
            text: qsTrId('id_cancel_twofactor_reset')
        }
    }
}
