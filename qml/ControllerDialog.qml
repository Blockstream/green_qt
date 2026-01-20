import Blockstream.Green
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDialog {
    id: self
    objectName: "ControllerDialog"

    default property alias contentItemData: stack_layout.data
    required property Controller controller

    property bool autoDestroy: false
    onClosed: if (autoDestroy) destroy()
    closePolicy: Popup.CloseOnEscape

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
                    const groups = self.controller?.dispatcher?.groups ?? []
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
            AnimLoader {
                readonly property SignTransactionTask task: {
                    const groups = self.controller?.dispatcher?.groups ?? []
                    for (let j = 0; j < groups.length; j++) {
                        const group = groups[j]
                        for (let i = 0; i < group.tasks.length; i++) {
                            const task = group.tasks[i]
                            if (!(task instanceof SignTransactionTask)) continue
                            if (!(task.resolver instanceof SignTransactionResolver)) continue
                            if (!(task.status === Task.Active)) continue
                            if (!(task.session.context.device instanceof LedgerDevice)) continue
                            return task
                        }
                    }
                    return null
                }
                id: ledger_sign_transaction_loader
                animated: true
                active: !!ledger_sign_transaction_loader.task
                sourceComponent: LedgerSignTransactionView {
                    wallet: ledger_sign_transaction_loader.task.session.context.wallet
                    resolver: ledger_sign_transaction_loader.task.resolver
                }
            }
            AnimLoader {
                readonly property SignTransactionTask task: {
                    const groups = self.controller?.dispatcher?.groups ?? []
                    for (let j = 0; j < groups.length; j++) {
                        const group = groups[j]
                        for (let i = 0; i < group.tasks.length; i++) {
                            const task = group.tasks[i]
                            if (!(task instanceof SignTransactionTask)) continue
                            if (!(task.resolver instanceof SignLiquidTransactionResolver)) continue
                            if (!(task.status === Task.Active)) continue
                            if (!(task.session.context.device instanceof LedgerDevice)) continue
                            return task
                        }
                    }
                    return null
                }
                id: ledger_sign_liquid_transaction_loader
                animated: true
                active: !!ledger_sign_liquid_transaction_loader.task
                sourceComponent: SignLiquidTransactionResolverView {
                    wallet: ledger_sign_liquid_transaction_loader.task.session.context.wallet
                    resolver: ledger_sign_liquid_transaction_loader.task.resolver
                }
            }
            AnimLoader {
                readonly property CreateAccountTask task: {
                    const groups = self.controller?.dispatcher?.groups ?? []
                    for (let j = 0; j < groups.length; j++) {
                        const group = groups[j]
                        for (let i = 0; i < group.tasks.length; i++) {
                            const task = group.tasks[i]
                            if (!(task instanceof CreateAccountTask)) continue
                            if (!(task.resolver instanceof SignMessageResolver)) continue
                            if (!(task.status === Task.Active)) continue
                            if (!(task.session.context.device instanceof JadeDevice)) continue
                            return task
                        }
                    }
                    return null
                }
                id: jade_sign_message_loader
                animated: true
                active: !!jade_sign_message_loader.task
                sourceComponent: JadeSignMessageView {
                    resolver: jade_sign_message_loader.task.resolver
                }
            }
        }
    }
}
