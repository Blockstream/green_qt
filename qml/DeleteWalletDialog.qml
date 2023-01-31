import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: dialog
    title: qsTrId('id_delete_wallet')
    controller: Controller {
        wallet: dialog.wallet
    }
    width: 400
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                property bool destructive: true
                text: qsTrId('id_delete_wallet')
                enabled: confirm_checkbox.checked
                onTriggered: controller.deleteWallet()
            }
        ]
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
    }
}
