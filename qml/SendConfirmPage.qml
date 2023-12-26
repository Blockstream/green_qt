import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Account account
    required property Asset asset
    required property Recipient recipient
    required property bool fiat
    required property string unit
    required property var transaction
    readonly property string value: recipient_convert.result[self.fiat ? 'fiat' : UtilJS.normalizeUnit(self.unit)] ?? ''
    Convert {
        id: recipient_convert
        account: self.account
        asset: self.asset
        unit: 'sats'
        value: self.recipient.amount
    }
    /*
    readonly property AuthHandlerTask task: {
        const groups = controller.monitor.groups
        for (let i = 0; i < groups.length; i++) {
            const group = groups[i]
            const tasks = group.tasks
            for (let j = 0; j < tasks.length; j++) {
                const task = tasks[j]
                if (task instanceof AuthHandlerTask) {
                    switch (task.result.status) {
                    case 'request_code':
                    case 'resolve_code':
                        return task
                    default:
                    }
                }
            }
        }
        return null
    }
    onTaskChanged: (task) => {
        if (self.task) {
            self.StackView.view.push(task_page, { task: self.task })
        }
    }
    */
    TaskPageFactory {
        monitor: controller.monitor
        target: self.StackView.view
    }

//    Component {
//        id: task_page
//        StackViewPage {
//            required property Task task
//            id: xxx
//            contentItem: AuthHandlerTaskView {
//                task: xxx.task
//            }
//        }
//    }

    SignTransactionController {
        id: controller
        context: self.context
        account: self.account
        transaction: self.transaction
        onTransactionCompleted: transaction => self.StackView.view.push(transaction_completed_page, { transaction })
        // onTransactionCompleted: transaction => self.StackView.view.replace(null, transaction_completed_page, { transaction }, StackView.PushTransition)
    }
    id: self
    title: qsTrId('id_confirm_transaction')
    contentItem: ColumnLayout {
        FieldTitle {
            text: 'Asset & Account'
        }
        AccountAssetField {
            Layout.bottomMargin: 15
            Layout.fillWidth: true
            account: self.account
            asset: self.asset
            readonly: true
        }
        FieldTitle {
            text: qsTrId('id_address')
        }
        Label {
            Layout.bottomMargin: 15
            Layout.fillWidth: true
            background: Rectangle {
                color: '#222226'
                radius: 5
            }
            padding: 20
            font.pixelSize: 14
            font.weight: 500
            elide: Label.ElideMiddle
            text: self.recipient.address
        }
        FieldTitle {
            text: qsTrId('Amount')
        }
        AmountField {
            Layout.bottomMargin: 15
            Layout.fillWidth: true
            account: self.account
            asset: self.asset
            readOnly: true
            fiat: self.fiat
            unit: self.unit
            value: self.value
            text: self.value
        }
        VSpacer {
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_confirm_transaction')
            onClicked: controller.sign()
        }
    }
    Component {
        id: transaction_completed_page
        TransactionCompletedPage {
        }
    }
}
