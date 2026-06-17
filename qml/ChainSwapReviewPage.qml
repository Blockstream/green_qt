import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import 'util.js' as UtilJS

StackViewPage {
    required property Context context
    required property var quote
    required property Account receiveAccount
    required property Asset receiveAsset
    required property Account sendAccount
    required property Asset sendAsset
    required property bool fiat
    required property string unit
    required property real feeRate
    property bool note: false
    ReceiveAddressController {
        id: refund_address_controller
        context: self.context
        session: self.sendAccount.session
        account: self.sendAccount
        asset: self.sendAsset
    }
    ReceiveAddressController {
        id: claim_address_controller
        context: self.context
        session: self.receiveAccount.session
        account: self.receiveAccount
        asset:  self.receiveAsset
    }
    ChainSwapController {
        id: chain_swap_controller
        context: self.context
        refundAddress: refund_address_controller.address
        claimAddress: claim_address_controller.address
        amount: self.quote.send_amount
    }
    CreateTransactionController {
        id: create_transaction_controller
        context: self.context
        account: self.sendAccount
        asset: self.sendAsset
        feeRate: self.feeRate
        recipient.convert.unit: self.sendAccount.session.unit
        recipient.convert.input: ({ satoshi: chain_swap_controller.swap?.data?.expectedAmount ?? '' })
        recipient.address: chain_swap_controller.swap?.data?.lockupAddress ?? ''
    }
    SignTransactionController {
        id: sign_transaction_controller
        context: self.context
        account: self.sendAccount
        memo: note_text_area.text
        transaction: create_transaction_controller.transaction
        onTransactionCompleted: transaction => {
            chain_swap_controller.setLockupTransaction(transaction.chainTransaction)
            Analytics.recordEvent('swap_internal', AnalyticsJS.segmentationSwap(Settings, self.context, { 
                from: UtilJS.swapNetworkType(self.sendAccount.network),
                to: UtilJS.swapNetworkType(self.receiveAccount.network)
            }))
            self.pushPage(completed_page, { transaction })
        }
        onFailed: (error) => {
            const segmentation = AnalyticsJS.segmentationSubAccount(Settings, self.sendAccount)
            segmentation.error = error
            Analytics.recordEvent('failed_transaction', segmentation)
            self.pushPage(error_page, { error })
        }
    }
    TaskPageFactory {
        title: self.title
        monitor: sign_transaction_controller.monitor
        target: self.StackView.view
        onClosed: self.closeClicked()
    }
    id: self
    title: qsTrId('id_review')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        spacing: 5
        alignment: Qt.AlignTop
        TextArea {
            Layout.fillWidth: true
            Layout.minimumHeight: 150
            text: JSON.stringify(chain_swap_controller.swap?.data ?? null, null, 4)
            visible: Qt.application.arguments.indexOf('--debug') > 0
        }
        FieldTitle {
            Layout.topMargin: 0
            text: 'From'
        }
        AccountAssetField {
            Layout.fillWidth: true
            account: self.sendAccount
            asset: self.sendAsset
            readonly: true
        }
        FieldTitle {
            text: 'To'
        }
        AccountAssetField {
            Layout.fillWidth: true
            account: self.receiveAccount
            asset: self.receiveAsset
            readonly: true
        }
        FieldTitle {
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            session: self.receiveAccount.session
            readOnly: true
            fiat: self.fiat
            unit: self.unit
            error: {
                if (continue_button.busy) return null
                return create_transaction_controller.transaction?.error
            }
            convert: Convert {
                asset: self.receiveAsset
                context: self.context
                input: ({ satoshi: self.quote.receive_amount })
                unit: self.unit
            }
        }
        ErrorPane {
            Layout.topMargin: -15
            error: amount_field.error
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 15
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
        GTextArea {
            Layout.fillWidth: true
            id: note_text_area
            visible: self.note
            wrapMode: TextArea.Wrap
        }
        VSpacer {
        }
        ColumnLayout {
            spacing: 5
            visible: !continue_button.busy && (create_transaction_controller.transaction?.transaction?.length ?? 0) > 0 && (create_transaction_controller.transaction?.error?.length ?? 0) === 0
            Fee {
                id: total_fees
                info: true
                text: 'Total Fees'
                convert: Convert {
                    context: self.context
                    account: self.sendAccount
                    input: ({ satoshi: Number(self.quote.send_amount ?? 0) - Number(self.quote.receive_amount ?? 0) + Number(create_transaction_controller.transaction?.fee ?? 0) })
                    unit: amount_field.convert.unit
                }
                Popup {
                    background: Rectangle {
                        radius: 10
                        color: '#252525'
                        opacity: 0.9
                        border.color: '#383838'
                        border.width: 1
                    }
                    padding: 16
                    visible: total_fees.infoHovered
                    x: parent.width / 2 - width / 2
                    y: -height - 10
                    contentItem: ColumnLayout {
                        spacing: 5
                        Fee {
                            Layout.minimumWidth: 350
                            text: 'Network Fee'
                            convert: Convert {
                                context: self.context
                                account: self.sendAccount
                                input: ({ satoshi: Number(self.quote.send_amount ?? 0) - Number(self.quote.receive_amount ?? 0) + Number(create_transaction_controller.transaction?.fee ?? 0) - Number(chain_swap_controller.swap?.data?.boltzFee ?? 0) })
                                unit: amount_field.convert.unit
                            }
                        }
                        Label {
                            color: '#FFFFFF'
                            opacity: 0.5
                            text: 'Paid for transaction confirmation'
                        }
                        Fee {
                            Layout.topMargin: 5
                            text: 'Swap Fee'
                            convert: Convert {
                                context: self.context
                                account: self.sendAccount
                                input: ({ satoshi: Number(chain_swap_controller.swap?.data?.boltzFee ?? 0) })
                                unit: amount_field.convert.unit
                            }
                        }
                        Label {
                            color: '#FFFFFF'
                            opacity: 0.5
                            text: 'Covers swap service'
                        }
                    }
                }
            }
            Fee {
                text: 'Total Spent'
                convert: Convert {
                    context: self.context
                    account: self.sendAccount
                    input: ({ satoshi: Number(self.quote.send_amount ?? 0) + Number(create_transaction_controller.transaction?.fee ?? 0) })
                    unit: amount_field.convert.unit
                }
            }
            Rectangle {
                Layout.preferredHeight: 1
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                Layout.fillWidth: true
                opacity: 0.2
                color: '#FFFFFF'
            }
            Fee {
                labelOpacity: 1
                outputOpacity: 1
                fiat: true
                text: 'Total to Receive'
                convert: Convert {
                    context: self.context
                    account: self.receiveAccount
                    input: ({ satoshi: self.quote.receive_amount })
                    unit: amount_field.convert.unit
                }
            }
        }
    }
    footerItem: PrimaryButton {
        id: continue_button
        enabled: !continue_button.busy && (create_transaction_controller.transaction?.transaction?.length ?? 0) > 0 && (create_transaction_controller.transaction?.error?.length ?? 0) === 0
        busy: chain_swap_controller.busy || !(create_transaction_controller.monitor?.idle ?? true) || !(sign_transaction_controller.monitor?.idle ?? true)
        text: qsTrId('id_confirm')
        onClicked: sign_transaction_controller.sign()
    }
    Component {
        id: error_page
        ErrorPage {
            title: self.title
        }
    }
    Component {
        id: completed_page
        TransactionCompletedPage {
            title: qsTrId('id_success')
            onCloseClicked: self.closeClicked()
        }
    }
    component Fee: RowLayout {
        property alias text: label.text
        property bool fiat: false
        property bool info: false
        property alias infoHovered: info_hover_handler.hovered
        property real labelOpacity: 0.9
        property real outputOpacity: 0.7
        property real fiatOpacity: 0.5
        required property Convert convert
        Layout.fillWidth: true
        id: fee
        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            opacity: fee.labelOpacity
            Label {
                id: label
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 500
            }
            Image {
                source: 'qrc:/svg2/info.svg'
                visible: fee.info
                HoverHandler {
                    id: info_hover_handler
                }
            }
            HSpacer {
            }
        }
        ColumnLayout {
            Label {
                Layout.alignment: Qt.AlignRight
                font.pixelSize: 14
                font.weight: 500
                opacity: fee.outputOpacity
                text: fee.convert.output.label
            }
            Label {
                Layout.alignment: Qt.AlignRight
                opacity: fee.fiatOpacity
                font.pixelSize: 12
                font.weight: 400
                text: '~ ' + fee.convert.fiat.label
                visible: fee.fiat && fee.convert.fiat.available
            }
        }
    }
}
