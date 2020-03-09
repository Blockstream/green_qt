import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import './views'

Dialog {
    id: controller_dialog
    property Controller controller
    property alias initialItem: stack_view.initialItem
    property string description
    property string placeholder
    property string doneText

    property real minimumHeight: 0
    property real minimumWidth: 0

    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    Overlay.modal: Rectangle {
        color: "#70000000"
    }

    anchors.centerIn: parent
    clip: true
    horizontalPadding: 16
    verticalPadding: 0
    modal: true

    onRejected: destroy()

    header: Item {
        implicitHeight: 48
        implicitWidth: title_label.implicitWidth + reject_button.implicitWidth + 32
        Label {
            id: title_label
            text: title
            anchors.left: parent.left
            anchors.margins: 16
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 16
            font.capitalization: Font.AllUppercase
        }
        ToolButton {
            id: reject_button
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 8
            icon.source: 'assets/svg/cancel.svg'
            icon.width: 16
            icon.height: 16
            onClicked: reject()
        }
    }

    footer: Item {
        implicitHeight: 48
        Row {
            anchors.margins: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            Repeater {
                model: stack_view.currentItem ? stack_view.currentItem.actions : []
                Button {
                    flat: true
                    action: modelData
                }
            }
        }
    }

    ControllerResult {
        status: 'request_code'
        stackView: stack_view
        WizardPage {
            ColumnLayout {
                anchors.centerIn: parent
                Repeater {
                    model: controller.result.methods
                    Button {
                        property string method: modelData
                        icon.source: `assets/svg/2fa_${method}.svg`
                        icon.color: 'transparent'
                        flat: true
                        text: method
                        onClicked: controller.requestCode(method)
                    }
                }
            }
        }
    }

    ControllerResult {
        status: 'resolve_code'
        stackView: stack_view
        WizardPage {
            actions: [
                Action {
                    text: qsTr('id_back')
                    onTriggered: controller.cancel()
                },
                Action {
                    text: qsTr('id_next')
                    onTriggered: controller.resolveCode(code_field.text)
                }
            ]
            Column {
                Label {
                    text: `Enter the code you received by ${controller.result.method}`
                }
                Label {
                    visible: !!controller.result.attempts_remaining
                    text: `${controller.result.attempts_remaining} attempts remaining`
                }
                TextField {
                    id: code_field
                    placeholderText: 'code'
                }
            }
        }
    }

    ControllerResult {
        status: 'done'
        stackView: stack_view
        WizardPage {
            actions: Action {
                text: 'OK'
                onTriggered: controller_dialog.accept()
            }
            Label {
                text: doneText
            }
        }
    }

    ControllerResult {
        status: 'error'
        stackView: stack_view
        Label {
            text: controller.result.error
            property list<Action> actions
        }
    }

    StackView {
        id: stack_view
        implicitHeight: Math.max(currentItem.implicitHeight, minimumHeight)
        implicitWidth: Math.max(currentItem.implicitWidth, minimumWidth)
    }
}
