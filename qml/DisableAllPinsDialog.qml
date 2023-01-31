import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: dialog
    title: qsTrId('id_disable_pin_access')
    controller: Controller {
        wallet: dialog.wallet
    }
    width: 400
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_cancel')
                onTriggered: dialog.reject()
            },
            Action {
                property bool destructive: true
                text: qsTrId('id_disable_pin_access')
                enabled: confirm_checkbox.checked
                onTriggered: {
                    controller.disableAllPins()
                    dialog.accept()
                }
            }
        ]
        Label {
            Layout.fillWidth: true
            text: qsTrId('id_this_will_disable_pin_login_for')
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
                text: qsTrId('id_i_confirm_i_want_to_disable_pin')
            }
        }
    }
}
