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
        id: controller
        context: self.context
        onEmpty: self.accept()
        onMessageChanged: {
            confirm_checkbox.enabled = true
            shouldOpen = true
        }
    }
    // TODO: push view for hw signing
    ColumnLayout {
        GFlickable {
            id: flickable
            clip: true
            Layout.maximumHeight: 300
            Layout.preferredHeight: message_label.height
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: message_label.height

            Label {
                id: message_label
                padding: 0
                text: controller.message
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
        RowLayout {
            Layout.fillHeight: false
            HSpacer {
            }
            GButton {
                text: qsTrId('id_skip')
                onClicked: self.reject()
            }
            GButton {
                enabled: confirm_checkbox.checked
                text: qsTrId('id_accept')
                onClicked: {
                    confirm_checkbox.checked = false
                    confirm_checkbox.enabled = false
                    controller.ack()
                }
            }
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
