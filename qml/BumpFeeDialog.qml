import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ControllerDialog {
    required property Transaction transaction
    readonly property Account account: transaction.account

    id: self
    title: qsTrId('id_increase_fee')
    wallet: self.account.context.wallet
    controller: BumpFeeController {
        id: controller
        context: self.context
        account: self.account
        transaction: self.transaction
        onFinished: Analytics.recordEvent('send_transaction', AnalyticsJS.segmentationTransaction(self.account, {
            address_input: 'paste',
            transaction_type: 'bump',
            with_memo: false,
        }))
    }

    ColumnLayout {
        id: layout
        spacing: 16
        SectionLabel {
            text: qsTrId('id_previous_fee')
        }
        Label {
            text: qsTrId('id_fee') + ': ' + formatAmount(self.account, transaction.data.fee) + ' ≈ ' +
                  formatFiat(transaction.data.fee)
        }
        Label {
            text: qsTrId('id_fee_rate') + ': ' + Math.round(transaction.data.fee_rate / 10 + 0.5) / 100 + ' sat/vB'
        }

        SectionLabel {
            text: qsTrId('id_new_fee')
        }
        Label {
            text: qsTrId('id_fee') + ': '  + formatAmount(self.account, controller.tx.fee) + ' ≈ ' +
                  formatFiat(controller.tx.fee)
        }
        Label {
            text: qsTrId('id_fee_rate') + ': ' + Math.round(controller.tx.fee_rate / 10 + 0.5) / 100 + ' sat/vB'
        }

        RowLayout {
            spacing: constants.s1
            FeeComboBox {
                account: self.account
                id: fee_combo
                Layout.fillWidth: true
                Layout.minimumWidth: 270
                extra: [{ text: qsTrId('id_custom') }]
                onFeeRateChanged: {
                    if (feeRate) {
                        controller.feeRate = feeRate
                    }
                }
                onCurrentIndexChanged: {
                    if (currentIndex === 3) {
                        custom_fee_field.clear()
                        custom_fee_field.forceActiveFocus()
                    }
                }
            }
            GTextField {
                id: custom_fee_field
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
        FixedErrorBadge {
            Layout.alignment: Qt.AlignHCenter
            pointer: false
            error: controller.tx.error
        }
        RowLayout {
            HSpacer {
            }
            GButton {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_next')
                enabled: controller.tx && controller.tx.error === ''
                highlighted: true
                onClicked: controller.bumpFee()
            }
        }
    }

    AnimLoader {
        animated: true
        active: controller.signedTransaction
        sourceComponent: ColumnLayout {
            spacing: constants.p1
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: 'qrc:/svg/check.svg'
                sourceSize.width: 64
                sourceSize.height: 64
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTrId('id_transaction_sent')
                font.pixelSize: 20
            }
            CopyableLabel {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: constants.p1
                font.pixelSize: 12
                delay: 50
                text: controller.signedTransaction.data.txhash
                onCopy: Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(self.account))
            }
            VSpacer {
            }
        }
    }
}
