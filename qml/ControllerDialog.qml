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

    property bool autoDestroy: false
    onClosed: if (autoDestroy) destroy()


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
        gauth: 'id_authenticator_app',
        phone: 'id_phone_call',
        sms: 'id_sms'
    })

    Connections {
        target: controller
        function onFinished() { stack_view.push(doneComponent) }
        function onError(handler) { push(handler, errorComponent) }
        function onRequestCode(handler) { push(handler, requestCodeComponent) }
        function onResolver(resolver) {
            if (resolver instanceof TwoFactorResolver) {
                stack_view.push(resolveCodeComponent, { resolver })
            } else if (resolver instanceof SignTransactionResolver) {
                stack_view.push(sign_transaction_resolver_view_component, { resolver })
                resolver.resolve()
            } else if (resolver instanceof SignLiquidTransactionResolver) {
                stack_view.push(sign_liquid_transaction_resolver_view_component, { resolver })
                resolver.resolve()
            } else {
                // automatically resolve
                resolver.resolve()
            }
        }
    }

    function push(handler, component) {
        stack_view.push(component, { handler })
    }

    Component {
        id: sign_transaction_resolver_view_component
        SignTransactionResolverView {}
    }

    Component {
        id: sign_liquid_transaction_resolver_view_component
        SignLiquidTransactionResolverView {}
    }

    property Component requestCodeComponent: ColumnLayout {
        property Handler handler
        Repeater {
            // TODO: handler is deleted while this view is on the stack view
            model: handler ? handler.result.methods : null
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
        property TwoFactorResolver resolver
        actions: [
            Action {
                text: qsTrId('id_next')
                enabled: code_field.acceptableInput
                onTriggered: {
                    resolver.code = code_field.text
                    resolver.resolve()
                }
            }
        ]
        Connections {
            target: resolver
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
                source: `qrc:/svg/2fa_${resolver.method}.svg`
                sourceSize.width: 64
                sourceSize.height: 64
            }
            Label {
                id: enterCodeText
                text: qsTrId('id_please_provide_your_1s_code').arg(resolver.method)
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
                visible: resolver.attemptsRemaining < 3 && resolver.method !== 'gauth'
                anchors.horizontalCenter: enterCodeText.horizontalCenter
                text: qsTrId('id_attempts_remaining_d').arg(resolver.attemptsRemaining)
                font.pixelSize: 10
            }
        }
    }

    property Component doneComponent: WizardPage {
        actions: Action {
            text: qsTrId('id_ok')
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
