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
            icon.source: 'qrc:/svg/cancel.svg'
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

    property var method_label: ({
        email: 'id_email',
        gauth: 'id_google_auth',
        phone: 'id_phone_call',
        sms: 'id_sms'
    })

    Connections {
        target: controller
        function onFinished() { stack_view.push(doneComponent) }
        function onError(handler) { push(handler, errorComponent) }
        function onRequestCode(handler) { push(handler, requestCodeComponent) }
        function onResolveCode(handler) { push(handler, resolveCodeComponent) }
    }

    function push(handler, component) {
        stack_view.push(component, { handler })
    }

    property Component requestCodeComponent: ColumnLayout {
        property Handler handler
        Repeater {
            model: handler.result.methods
            Button {
                property string method: modelData
                icon.source: `qrc:/svg/2fa_${method}.svg`
                icon.color: 'transparent'
                flat: true
                Layout.fillWidth: true
                text: qsTrId(method_label[method])
                onClicked: handler.request(method)
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    property Component resolveCodeComponent: WizardPage {
        property Handler handler
        actions: [
            Action {
                text: qsTrId('id_next')
                enabled: code_field.acceptableInput
                onTriggered: handler.resolve(code_field.text)
            }
        ]
        Connections {
            target: handler
            function onInvalidCode() {
                code_field.clear()
                code_field.ToolTip.show(qsTrId('id_invalid_twofactor_code'), 1000);
                code_field.forceActiveFocus()
            }
        }
        Column {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            Image {
                anchors.horizontalCenter: enterCodeText.horizontalCenter
                source: `qrc:/svg/2fa_${handler.result.method}.svg`
                sourceSize.width: 64
                sourceSize.height: 64
            }
            Label {
                id: enterCodeText
                text: qsTrId('id_please_provide_your_1s_code').arg(handler.result.method)
            }
            TextField {
                id: code_field
                horizontalAlignment: Qt.AlignHCenter
                validator: RegExpValidator {
                    regExp: /[0-9]{6}/
                }
                anchors.horizontalCenter: enterCodeText.horizontalCenter
            }
            Label {
                visible: !!handler.result.attempts_remaining
                anchors.horizontalCenter: enterCodeText.horizontalCenter
                text: qsTrId('id_attempts_remaining_d').arg(handler.result.attempts_remaining)
                font.pixelSize: 10
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
                source: 'qrc:/svg/check.svg'
                sourceSize.width: 64
                sourceSize.height: 64
            }
            Label {
                id: doneLabel
                text: doneText
                font.pixelSize: 20

            }
        }
    }

    property Component errorComponent: Label {
        property Handler handler
        property list<Action> actions
        text: 'ERROR:' + handler.result.error
    }

    StackView {
        id: stack_view
        anchors.centerIn: parent
        implicitHeight: Math.max(currentItem.implicitHeight, minimumHeight)
        implicitWidth: Math.max(currentItem.implicitWidth, minimumWidth)
    }
}
