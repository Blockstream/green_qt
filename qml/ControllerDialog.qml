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
    closePolicy: Popup.NoAutoClose
    toolbar: stack_view.currentItem.toolbar
    footer: DialogFooter {
        HSpacer {}
        Repeater {
            model: stack_view.currentItem ? stack_view.currentItem.actions : []
            GButton {
                destructive: modelData.destructive || false
                highlighted: modelData.highlighted || false
                large: true
                action: modelData
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
        Spacer {
        }
    }

    property Component resolveCodeComponent: WizardPage {
        property TwoFactorResolver resolver
        Component.onCompleted: code_field.forceActiveFocus()
        Connections {
            target: resolver
            function onInvalidCode() {
                code_field.clear()
                code_field.ToolTip.show(qsTrId('id_invalid_twofactor_code'), 1000);
                code_field.forceActiveFocus()
            }
        }
        Column {
            spacing: constants.s1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            Image {
                anchors.horizontalCenter: enterCodeText.horizontalCenter
                source: resolver ? `qrc:/svg/2fa_${resolver.method}.svg` : ''
                sourceSize.width: 64
                sourceSize.height: 64
            }
            Loader {
                active: resolver && wallet.config[resolver.method].enabled
                anchors.horizontalCenter: enterCodeText.horizontalCenter
                sourceComponent: Label {
                    text: {
                        if (resolver.method === 'gauth') return qsTrId('id_authenticator_app')
                        return wallet.config[resolver.method].data
                    }
                    color: constants.c100
                    font.pixelSize: 14
                }
            }
            Label {
                id: enterCodeText
                text: resolver ? qsTrId('id_please_provide_your_1s_code').arg(resolver.method) : ''
            }
            GTextField {
                id: code_field
                horizontalAlignment: Qt.AlignHCenter
                onTextChanged: {
                    if (acceptableInput) {
                        resolver.code = code_field.text
                        resolver.resolve()
                    }
                }
                validator: RegExpValidator {
                    regExp: /[0-9]{6}/
                }
                anchors.horizontalCenter: enterCodeText.horizontalCenter
            }
            Label {
                visible: resolver ? (resolver.attemptsRemaining < 3 && resolver.method !== 'gauth') : null
                anchors.horizontalCenter: enterCodeText.horizontalCenter
                text: resolver ? qsTrId('id_attempts_remaining_d').arg(resolver.attemptsRemaining) : ''
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

    contentItem: StackView {
        id: stack_view
        implicitHeight: Math.max(currentItem.implicitHeight, minimumHeight)
        implicitWidth: Math.max(currentItem.implicitWidth, minimumWidth)
    }
}
