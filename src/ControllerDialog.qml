import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import './views'

Dialog {
    property Controller controller
    property alias initialItem: stack_view.initialItem
    property alias goo: stack_view

    anchors.centerIn: parent
    clip: true
    height: 500
    horizontalPadding: 50
    modal: true
    width: 600

    footer: DialogButtonBox {
        Repeater {
            model: stack_view.currentItem ? stack_view.currentItem.actions : []
            Button {
                flat: true
                action: modelData
            }
        }
    }

    StateGroup {
        state: controller.state
        transitions: [
            Transition {
                to: 'RESOLVE_CODE'
                StackViewPushAction {
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
                            TextField {
                                id: code_field
                                placeholderText: 'code'
                            }
                        }

                    }
                }
            },
            Transition {
                from: 'RESOLVE_CODE'
                to: ''
                ScriptAction {
                    script: stack_view.pop()
                }
            },
            Transition {
                to: 'DONE'
                StackViewPushAction {
                    stackView: stack_view
                    WizardPage {
                        actions: Action {
                            text: 'OK'
                            onTriggered: accept()
                        }
                        Label {
                            text: 'DONE!'
                        }
                    }
                }
            },
            Transition {
                to: 'ERROR'
                StackViewPushAction {
                    stackView: stack_view
                    Label {
                        text: controller.result.error
                        property list<Action> actions
                    }
                }
            }
        ]
    }

    StackView {
        id: stack_view
        anchors.fill: parent
    }
}
