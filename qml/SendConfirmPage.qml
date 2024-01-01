import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
    property bool note: false
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
        memo: note_text_area.text
        onTransactionCompleted: transaction => self.StackView.view.push(transaction_completed_page, { transaction })
        // onTransactionCompleted: transaction => self.StackView.view.replace(null, transaction_completed_page, { transaction }, StackView.PushTransition)
    }
    id: self
    title: qsTrId('id_confirm_transaction')
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            width: flickable.width
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
                text: qsTrId('id_amount')
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
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_add_note')
                visible: !self.note
                onClicked: {
                    self.note = true
                    note_text_area.forceActiveFocus()
                }
            }
            FieldTitle {
                text: qsTrId('id_note')
                visible: self.note
            }
            TextArea {
                Layout.fillWidth: true
                id: note_text_area
                topPadding: 20
                bottomPadding: 20
                leftPadding: 20
                rightPadding: 20
                visible: self.note
                background: Rectangle {
                    color: '#222226'
                    radius: 5
                }
            }
        }
    }
    footer: ColumnLayout {
        spacing: 10
        Convert {
            id: fee_convert
            account: self.account
            unit: 'sats'
            value: String(self.transaction.fee)
        }
        Convert {
            id: total_convert
            account: self.account
            unit: 'sats'
            value: String(self.transaction.fee - self.transaction.satoshi.btc)
        }
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                opacity: 0.5
                text: qsTrId('id_network_fee')
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    opacity: 0.5
                    font.pixelSize: 14
                    font.weight: 500
                    text: fee_convert.unitLabel
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    opacity: 0.5
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~ ' + fee_convert.fiatLabel
                }
            }
        }
        Rectangle {
            Layout.preferredHeight: 1
            Layout.fillWidth: true
            opacity: 0.4
            color: '#FFF'
        }
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                opacity: 0.5
                text: qsTrId('id_total')
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 500
                    text: total_convert.unitLabel
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 500
                    opacity: 0.5
                    text: '~ ' + total_convert.fiatLabel
                }
            }
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 200
            Layout.topMargin: 20
            text: qsTrId('id_confirm_transaction')
            onClicked: controller.sign()
        }
        RowLayout {
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignCenter
            opacity: 0.6
            Image {
                source: 'qrc:/svg2/info.svg'
            }
            Label {
                font.pixelSize: 12
                font.weight: 400
                text: qsTrId('id_fees_are_collected_by_bitcoin')
            }
        }
    }

    Component {
        id: transaction_completed_page
        TransactionCompletedPage {
        }
    }
}
