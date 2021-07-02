import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

ControllerDialog {
    required property Transaction transaction
    readonly property Account account: transaction.account

    id: self
    title: qsTrId('id_increase_fee')
    wallet: self.account.wallet
    controller: BumpFeeController {
        account: self.account
    }
    doneText: qsTrId('id_transaction_sent')
    minimumWidth: 500
    initialItem: FocusScope {
        property list<Action> actions: [
            Action {
                text: controller.tx.error !== '' ? qsTrId(controller.tx.error || '') : qsTrId('id_next')
                enabled: controller.tx && controller.tx.error === ''
                onTriggered: controller.bumpFee()
            }
        ]
        implicitHeight: layout.implicitHeight
        implicitWidth: layout.implicitWidth
        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: 16
            SectionLabel {
                text: qsTrId('id_previous_fee')
            }
            Label {
                text: qsTrId('id_fee') + ': ' + formatAmount(transaction.data.fee) + ' ≈ ' +
                      formatFiat(transaction.data.fee)
            }
            Label {
                text: qsTrId('id_fee_rate') + ': ' + Math.round(transaction.data.fee_rate / 10 + 0.5) / 100 + ' sat/vB'
            }

            SectionLabel {
                text: qsTrId('id_new_fee')
            }
            Label {
                text: qsTrId('id_fee') + ': '  + formatAmount(controller.tx.fee) + ' ≈ ' +
                      formatFiat(controller.tx.fee)
            }
            Label {
                text: qsTrId('id_fee_rate') + ': ' + Math.round(controller.tx.fee_rate / 10 + 0.5) / 100 + ' sat/vB'
            }

            RowLayout {
                FeeComboBox {
                    id: fee_combo
                    Layout.fillWidth: true
                    extra: [{ text: qsTrId('id_custom') }]
                    onFeeRateChanged: {
                        if (feeRate) {
                            controller.feeRate = feeRate
                        }
                    }
                }
                GTextField {
                    enabled: fee_combo.currentIndex === 3
                    onTextChanged: controller.feeRate = Number(text) * 1000
                    horizontalAlignment: TextField.AlignRight
                    validator: AmountValidator {
                    }
                    Label {
                        id: fee_unit_label
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.baseline: parent.baseline
                        text: 'sat/vB'
                    }
                    rightPadding: fee_unit_label.width + 16
                }
            }
        }
    }
    doneComponent: TransactionDoneView {
        dialog: self
        transaction: self.controller.signedTransaction
    }
}
