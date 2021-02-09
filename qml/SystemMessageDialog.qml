import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    required property Wallet wallet
    property string method
    property bool shouldOpen: false
    title: qsTrId('id_system_message')
    closePolicy: Popup.NoAutoClose
    autoDestroy: false
    controller: SystemMessageController {
        wallet: dialog.wallet
        onEmpty: dialog.close()
        onMessage: {
            message_label.text = text
            confirm_checkbox.enabled = true
            shouldOpen = true //dialog.open()
        }
    }
    // TODO: push view for hw signing
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_skip')
                onTriggered: dialog.close()
            },
            Action {
                enabled: confirm_checkbox.checked
                text: qsTrId('id_accept')
                onTriggered: {
                    confirm_checkbox.checked = false
                    confirm_checkbox.enabled = false
                    controller.ack()
                }
            }
        ]
        Label {
            id: message_label
            Layout.maximumWidth: 500
            Layout.fillWidth: true
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            onLinkActivated: Qt.openUrlExternally(link)
            textFormat: Label.MarkdownText
        }
        CheckBox {
            id: confirm_checkbox
            enabled: false
            text: qsTrId('id_i_confirm_i_have_read_and')
        }
    }
    Timer {
        //id: recheck_timer
        running: true
        repeat: true
        interval: 5000
        onTriggered: controller.check()
    }
}
