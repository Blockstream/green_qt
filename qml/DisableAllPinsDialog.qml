import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

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
            wrapMode: Label.WordWrap
        }
        CheckBox {
            Layout.fillWidth: true
            id: confirm_checkbox
            text: qsTrId('id_i_confirm_i_want_to_disable_pin')
        }
    }
}
