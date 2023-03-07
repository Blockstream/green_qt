import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: self
    title: qsTrId('id_cancel_twofactor_reset')
    controller: Controller {
        id: controller
        context: self.context
    }
    ColumnLayout {
        spacing: constants.s1
        Label {
            text: qsTrId('id_cancel_twofactor_reset')
        }
        GButton {
            Layout.alignment: Qt.AlignCenter
            highlighted: true
            text: qsTrId('id_next')
            onClicked: controller.cancelTwoFactorReset()
        }
    }
}
