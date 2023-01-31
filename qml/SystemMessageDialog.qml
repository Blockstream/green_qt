import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: self
    property bool shouldOpen: false
    title: qsTrId('id_system_message')
    closePolicy: Popup.NoAutoClose
    autoDestroy: false
    showRejectButton: false
    controller: SystemMessageController {
        wallet: self.wallet
        onEmpty: self.accept()
        onMessage: {
            message_label.text = text
            confirm_checkbox.enabled = true
            shouldOpen = true
        }
    }
    // TODO: push view for hw signing
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_skip')
                onTriggered: self.reject()
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
        GFlickable {
            id: flickable
            clip: true
            Layout.minimumHeight: 300
            Layout.maximumHeight: 300
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: message_label.height

            Label {
                id: message_label
                padding: 0
                width: flickable.availableWidth
                height: paintedHeight
                wrapMode: Text.Wrap
                onLinkActivated: Qt.openUrlExternally(link)
                textFormat: Label.MarkdownText
            }
        }
        CheckBox {
            id: confirm_checkbox
            enabled: false
            text: qsTrId('id_i_confirm_i_have_read_and')
        }
    }
    Timer {
        running: true
        repeat: true
        interval: 5000
        onTriggered: controller.check()
    }
    AnalyticsView {
        active: self.opened
        name: 'SystemMessage'
    }
}
