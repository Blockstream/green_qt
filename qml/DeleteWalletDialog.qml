import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: self
    objectName: "DeleteWalletDialog"
    title: qsTrId('id_delete_wallet')
    controller: Controller {
        id: controller
        context: self.context
    }
    ColumnLayout {
        spacing: constants.s1
        Label {
            Layout.fillWidth: true
            text: qsTrId('id_delete_permanently_your_wallet')
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            CheckBox {
                id: confirm_checkbox
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTrId('id_i_confirm_i_want_to_delete_this')
            }
        }
        GButton {
            Layout.alignment: Qt.AlignCenter
            destructive: true
            text: qsTrId('id_delete_wallet')
            enabled: confirm_checkbox.checked
            onClicked: controller.deleteWallet()
        }
    }
}
