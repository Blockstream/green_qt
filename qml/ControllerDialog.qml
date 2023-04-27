import Blockstream.Green
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDialog {
    id: self

    default property alias contentItemData: stack_layout.data
    required property Controller controller

    property bool autoDestroy: false
    onClosed: if (autoDestroy) destroy()
    closePolicy: Popup.CloseOnEscape

    ProgressIndicator {
        parent: toolbar
        Layout.minimumHeight: 24
        Layout.minimumWidth: 24
        indeterminate: self.controller?.dispatcher.busy ?? false
        progress: 0
        visible: opacity > 0
        opacity: self.controller?.dispatcher?.busy ? 1 : 0
        Behavior on opacity {
            SmoothedAnimation {
            }
        }
    }
    SessionBadge {
        parent: toolbar
        visible: !!self.controller?.context
        session: self.controller?.context?.session ?? null
    }
    GToolButton {
        id: info_button
        parent: toolbar
        visible: env !== 'Production'
        enabled: visible
        flat: true
        icon.source: 'qrc:/svg/info.svg'
        checkable: true
        checked: false
    }
/*
    footer: Label {
        visible: false
        font.pixelSize: 8
        text: {
            let t = ''
            for (let i = 0; i < stack_layout.children.length; ++i) {
                const child = stack_layout.children[i]
                t = t + child + '  task=' + child.task + '  active=' + child.active + ' status=' + (child.task?.result?.status ?? 'N/A') + ' focus=' + child.focus + ' active_focus=' + child.activeFocus + '\n'
            }
        }
    }
*/
//    Connections {
//        target: controller
//        function onFinished(handler) {
//            push(handler, doneComponent)
//        }
//        function onError(handler) {
//            if (handler.result.error === 'id_invalid_twofactor_code') {
//                push(handler, twoFactorAuthenticationErrorComponent)
//            } else {
//                push(handler, genericErrorComponent)
//            }
//        }
//        function onRequestCode(handler) { push(handler, requestCodeComponent) }
//        function onResolver(resolver) {
//            const wallet = self.wallet
//            if (resolver instanceof SignTransactionResolver) {
//                let component
//                if (resolver.device instanceof JadeDevice) {
//                    component = jade_sign_transaction_view
//                } else {
//                    component = ledger_sign_transaction_view
//                }
//                const view = component.createObject(stack_view, { resolver, wallet })
//                stack_view.push(view)
//                resolver.resolve()
//                return
//            }
//            if (resolver instanceof SignLiquidTransactionResolver) {
//                if (resolver.device instanceof JadeDevice) {
//                    const view = jade_sign_liquid_transaction_view.createObject(stack_view, { resolver, wallet })
//                    stack_view.push(view)
//                    resolver.resolve()
//                } else {
//                    stack_view.push(sign_liquid_transaction_resolver_view_component, { resolver, wallet })
//                    resolver.resolve()
//                }
//                return
//            }
//            if (resolver instanceof SignMessageResolver) {
//                if (resolver.device instanceof JadeDevice) {
//                    const view = jade_sign_message_view.createObject(stack_view, { resolver })
//                    stack_view.push(view)
//                    return
//                }
//            }
//            // automatically resolve
//            resolver.resolve()
//        }
//    }

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

    /*
    property Component genericErrorComponent: WizardPage {
        property Handler handler

        id: self
        actions: Action {
            text: qsTrId('id_ok')
            onTriggered: self.accept()
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
*/

    contentItem: RowLayout {
        spacing: 8
        StackLayout {
            id: stack_layout
            currentIndex: {
                let i
                let index = -1
                for (i = 0; i < stack_layout.children.length; ++i) {
                    const child = stack_layout.children[i]
                    if (!(child instanceof Item)) continue
                    if (child.active && index < 0) index = i
                }
                if (index >= 0) return index
                for (i = 0; i < stack_layout.children.length; ++i) {
                    const child = stack_layout.children[i]
                    if (!(child instanceof Item)) continue
                    if (child.active === undefined) return i
                }
                return 0
            }
            AnimLoader {
                readonly property AuthHandlerTask task: {
                    const groups = self.controller?.dispatcher?.groups
                    for (let j = 0; j < groups.length; j++) {
                        const group = groups[j]
                        for (let i = 0; i < group.tasks.length; i++) {
                            const task = group.tasks[i]
                            if (!(task instanceof AuthHandlerTask)) continue
                            if (!(task.status === Task.Active)) continue
                            if (!(task.result.status === 'request_code' || task.result.status === 'resolve_code')) continue
                            return task
                        }
                    }
                    return null
                }
                id: auth_handler_loader
                animated: true
                active: !!auth_handler_loader.task
                sourceComponent: AuthHandlerTaskView {
                    task: auth_handler_loader.task
                }
            }
// TODO each controller dialog should have a custom done view
            AnimLoader {
                id: done_loader
                animated: true
                active: false //sourceComponent && self.controller.dispatcher.status === TaskDispatcher.Finished
    //            {
    //                return false
    //                const tasks = self.controller?.dispatcher?.tasks ?? []
    //                if (tasks.length === 0) return false
    //                let result = true
    //                for (let i = 0; i < tasks.length; i++) {
    //                    const task = tasks[i]
    //                    if (task.status !== Task.Finished) result = false
    //                }
    //                return result
    //            }
                sourceComponent: ColumnLayout {
                    Spacer {
                    }
                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        source: 'qrc:/svg/check.svg'
                        sourceSize.width: 64
                        sourceSize.height: 64
                    }
                    Label {
                        text: qsTrId('id_done')
                        font.pixelSize: 20
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignHCenter
                    }
                    VSpacer {
                    }
                }
            }
        }
        TaskDispatcherInspector {
            Layout.fillHeight: true
            Layout.minimumWidth: 200
            dispatcher: controller.dispatcher
            visible: info_button.checked
        }
    }
}
