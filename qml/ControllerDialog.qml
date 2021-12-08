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
        sms: 'id_sms',
        telegram: 'id_telegram'
    })

    Connections {
        target: controller
        function onFinished() { stack_view.push(doneComponent) }
        function onError(handler) {
            if (handler.result.error === 'id_invalid_twofactor_code') {
                push(handler, twoFactorAuthenticationErrorComponent)
            } else {
                push(handler, genericErrorComponent)
            }
        }
        function onRequestCode(handler) { push(handler, requestCodeComponent) }
        function onResolver(resolver) {
            const wallet = controller_dialog.wallet
            if (resolver instanceof TwoFactorResolver) {
                stack_view.push(resolveCodeComponent, { resolver })
                return
            }
            if (resolver instanceof SignTransactionResolver) {
                let component
                if (resolver.device instanceof JadeDevice) {
                    component = jade_sign_transaction_view
                } else {
                    component = ledger_sign_transaction_view
                }
                const view = component.createObject(stack_view, { resolver, wallet })
                stack_view.push(view)
                resolver.resolve()
                return
            }
            if (resolver instanceof SignLiquidTransactionResolver) {
                if (resolver.device instanceof JadeDevice) {
                    const view = jade_sign_liquid_transaction_view.createObject(stack_view, { resolver, wallet })
                    stack_view.push(view)
                    resolver.resolve()
                } else {
                    stack_view.push(sign_liquid_transaction_resolver_view_component, { resolver, wallet })
                    resolver.resolve()
                }
                return                    
            }
            if (resolver instanceof SignMessageResolver) {
                if (resolver.device instanceof JadeDevice) {
                    const view = jade_sign_message_view.createObject(stack_view, { resolver })
                    stack_view.push(view)
                    return
                }
            }
            // automatically resolve
            resolver.resolve()
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

    Component {
        id: ledger_sign_transaction_view
        LedgerSignTransactionView {}
    }

    Component {
        id: jade_sign_transaction_view
        JadeSignTransactionView {}
    }

    Component {
        id: jade_sign_liquid_transaction_view
        JadeSignLiquidTransactionView {}
    }

    Component {
        id: jade_sign_message_view
        JadeSignMessageView {
        }
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
        contentItem: ColumnLayout {
            spacing: constants.s1
            Image {
                Layout.alignment: Qt.AlignCenter
                source: resolver ? `qrc:/svg/2fa_${resolver.method}.svg` : ''
                sourceSize.width: 64
                sourceSize.height: 64
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: resolver && wallet.config[resolver.method].enabled && !(resolver.handler instanceof TwoFactorResetHandler)
                visible: active
                sourceComponent: Label {
                    text: {
                        if (resolver.method === 'gauth') return qsTrId('id_authenticator_app')
                        return wallet.config[resolver.method].data
                    }
                    color: constants.c100
                    font.pixelSize: 14
                }
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: resolver && resolver.handler instanceof TwoFactorResetHandler
                visible: active
                sourceComponent: Label {
                    text: resolver.handler.email
                    color: constants.c100
                    font.pixelSize: 14
                }
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: resolver && resolver.method === 'telegram'
                visible: active
                sourceComponent: RowLayout {
                    spacing: constants.s1
                    ColumnLayout {
                        GButton {
                            Layout.fillWidth: true
                            large: true
                            text: 'Open in Browser'
                            onClicked: Qt.openUrlExternally(resolver.telegramBrowserUrl)
                        }
                        GButton {
                            Layout.fillWidth: true
                            large: true
                            text: 'Open Telegram'
                            onClicked: Qt.openUrlExternally(resolver.telegramAppUrl)
                        }
                    }
                    QRCode {
                        text: resolver.telegramAppUrl
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: resolver ? qsTrId('id_please_provide_your_1s_code').arg(resolver.method) : ''
            }
            Timer {
                id: delayed_resolve_timer
                interval: 300
                running: false
                repeat: false
                onTriggered: {
                    code_field.readOnly = false
                    resolver.resolve()
                }
            }
            GTextField {
                id: code_field
                Layout.alignment: Qt.AlignCenter
                onTextChanged: {
                    if (acceptableInput) {
                        code_field.readOnly = true
                        resolver.code = code_field.text
                        delayed_resolve_timer.start()
                    }
                }
                validator: RegExpValidator {
                    regExp: /[0-9]{6}/
                }
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: {
                    if (!resolver) return false
                    if (resolver.method === 'gauth') return false
                    if (resolver.method === 'telegram') return false
                    return resolver.attemptsRemaining < 3
                }
                visible: active
                sourceComponent: Label {
                    text: resolver ? qsTrId('id_attempts_remaining_d').arg(resolver.attemptsRemaining) : ''
                    font.pixelSize: 10
                }
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

    property Component genericErrorComponent: WizardPage {
        property Handler handler

        id: self
        actions: Action {
            text: qsTrId('id_ok')
            onTriggered: controller_dialog.accept()
        }
        GButton {
            anchors.centerIn: parent
            icon.source: 'qrc:/svg/warning.svg'
            baseColor: '#e5e7e9'
            textColor: 'black'
            highlighted: true
            large: true
            text: self.handler.result.error || qsTrId('There was an error processing this request')
            scale: hovered ? 1.01 : 1
            transformOrigin: Item.Center
            Behavior on scale {
                NumberAnimation {
                    easing.type: Easing.OutBack
                    duration: 400
                }
            }
        }
    }

    property Component twoFactorAuthenticationErrorComponent: WizardPage {
        actions: Action {
            text: qsTrId('id_ok')
            onTriggered: controller_dialog.accept()
        }
        GButton {
            anchors.centerIn: parent
            icon.source: 'qrc:/svg/warning.svg'
            baseColor: '#e5e7e9'
            textColor: 'black'
            highlighted: true
            large: true
            text: qsTrId('id_no_attempts_remaining')
            scale: hovered ? 1.01 : 1
            transformOrigin: Item.Center
            Behavior on scale {
                NumberAnimation {
                    easing.type: Easing.OutBack
                    duration: 400
                }
            }
        }
    }

    contentItem: StackView {
        id: stack_view
        implicitHeight: Math.max(currentItem.implicitHeight, minimumHeight)
        implicitWidth: Math.max(currentItem.implicitWidth, minimumWidth)
    }
}
