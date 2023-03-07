import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: dialog
    title: qsTrId('id_disable_pin_access')
    controller: Controller {
        context: dialog.wallet.context
    }
    ColumnLayout {
        spacing: constants.s1
        Spacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 360
            text: qsTrId('id_this_will_disable_pin_login_for')
            horizontalAlignment: Label.AlignHCenter
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignCenter
            CheckBox {
                id: confirm_checkbox
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTrId('id_i_confirm_i_want_to_disable_pin')
            }
        }
        GButton {
            Layout.alignment: Qt.AlignCenter
            destructive: true
            text: qsTrId('id_disable_pin_access')
            enabled: confirm_checkbox.checked
            onClicked: {
                controller.disableAllPins()
                dialog.accept()
            }
        }
        Spacer {
        }
    }
}
