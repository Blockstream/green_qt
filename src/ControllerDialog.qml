import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import './views'

Dialog {
    id: controller_dialog
    property Controller controller
    property alias initialItem: stack_view.initialItem
    property alias goo: stack_view
    property string icon

    anchors.centerIn: parent
    clip: true
    height: 500
    horizontalPadding: 50
    modal: true
    width: 600

    header: RowLayout {
        Label {
            text: title
            Layout.fillWidth: true
            Layout.margins: 16
        }
        Image {
            visible: icon.length > 0
            source: icon
            sourceSize.height: 32
            Layout.margins: 16
        }
    }

    footer: DialogButtonBox {
        Repeater {
            model: stack_view.currentItem ? stack_view.currentItem.actions : []
            Button {
                flat: true
                action: modelData
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
                    text: qsTr('id_next')
                    onTriggered: controller.resolveCode(code_field.text)
                },
                Action {
                    text: qsTr('id_back')
                    onTriggered: controller.cancel()
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
                text: 'DONE!'
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
        anchors.fill: parent
    }
}
