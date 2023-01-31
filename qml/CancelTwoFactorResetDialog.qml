import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: dialog
    title: qsTrId('id_cancel_twofactor_reset')
    controller: Controller {
        wallet: dialog.wallet
    }
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_next')
                onTriggered: controller.cancelTwoFactorReset()
            }
        ]
        Label {
            text: qsTrId('id_cancel_twofactor_reset')
        }
    }
}
