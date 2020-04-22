import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WalletDialog {
    id: controller_dialog
    property Controller controller
    property alias initialItem: stack_view.initialItem
    property string description
    property string placeholder
    property string doneText: qsTrId('id_done')

    property real minimumHeight: 0
    property real minimumWidth: 0

    onClosed: destroy()

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
            icon.source: '/svg/cancel.svg'
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
        ColumnLayout {
            Repeater {
                model: controller.result.methods
                Button {
                    property string method: modelData
                    icon.source: `svg/2fa_${method}.svg`
                    icon.color: 'transparent'
                    flat: true
                    text: method
                    Layout.fillWidth: true
                    onClicked: controller.requestCode(method)

                    Rectangle {
                        border.color: down ? Material.accentColor : hovered ? Material.foreground : 'gray'
                        border.width: 1
                        color: 'transparent'
                        anchors.fill: background
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
                    text: qsTrId('id_back')
                    onTriggered: controller.cancel()
                },
                Action {
                    text: qsTrId('id_next')
                    onTriggered: controller.resolveCode(code_field.text)
                }
            ]
            Column {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter
                Image {
                    anchors.horizontalCenter: enterCodeText.horizontalCenter
                    source: `svg/2fa_${controller.result.method}.svg`
                    sourceSize.width: 64
                    sourceSize.height: 64
                    opacity: matching ? 1 : 0
                    Behavior on opacity { OpacityAnimator { } }
                }
                Label {
                    id: enterCodeText
                    text: qsTrId('id_please_provide_your_1s_code').arg(controller.result.method)
                }
                TextField {
                    id: code_field
                    anchors.horizontalCenter: enterCodeText.horizontalCenter
                }
                Label {
                    visible: !!controller.result.attempts_remaining
                    anchors.horizontalCenter: enterCodeText.horizontalCenter
                    text: qsTrId('id_attempts_remaining_d').arg(controller.result.attempts_remaining)
                    font.pixelSize: 10
                }
            }
        }
    }

    property Component doneComponent: WizardPage {
        actions: Action {
            text: 'OK'
            onTriggered: controller_dialog.accept()
        }
        Column {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            Image {
                anchors.horizontalCenter: doneLabel.horizontalCenter
                source: '/svg/check.svg'
                sourceSize.width: 64
                sourceSize.height: 64
                opacity: matching ? 1 : 0
                Behavior on opacity { OpacityAnimator { } }
            }
            Label {
                id: doneLabel
                text: doneText
                font.pixelSize: 20

            }

        }
    }

    ControllerResult {
        status: 'done'
        stackView: stack_view
        component: doneComponent
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
        anchors.centerIn: parent
        implicitHeight: Math.max(currentItem.implicitHeight, minimumHeight)
        implicitWidth: Math.max(currentItem.implicitWidth, minimumWidth)
    }
}
