import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Account account
    required property Asset asset
    required property string input
    required property var recipient
    required property bool fiat
    required property string unit
    property bool note: self.recipient?.invoice?.description ?? self.recipient?.bolt12?.description ?? false
    readonly property string amount: {
        if (submarine_controller.swap?.data?.boltz_fee && self.recipient.invoice) {
            return String(Math.ceil(Number(self.recipient.invoice.amount_milli_satoshis) / 1000))
        }
        return Number(submarine_controller.swap?.data?.amount ?? 0) - Number(submarine_controller.swap?.data?.fee ?? 0)
    }
    ReceiveAddressController {
        id: receive_controller
        context: self.context
        account: self.account
    }
    SubmarineController {
        id: submarine_controller
        context: self.context
        recipient: self.recipient
        refundAddress: receive_controller.address?.address ?? ''
    }
    FeeEstimates {
        id: estimates
        session: self.account.session
    }
    CreateTransactionController {
        id: controller
        context: self.context
        account: self.account
        asset: self.asset
        feeRate: estimates.fees[3]
        recipient.convert.unit: self.account.session.unit
        recipient.convert.input: ({ satoshi: submarine_controller.swap?.data?.amount ?? '' })
        recipient.address: submarine_controller.swap?.data?.address ?? ''
    }
    SignTransactionController {
        id: sign_transaction_controller
        context: self.context
        account: self.account
        memo: note_text_area.text
        transaction: controller.transaction
        onTransactionCompleted: transaction => {
            submarine_controller.setLockupTransaction(transaction.chainTransaction)
            Analytics.recordEvent('swap_send', AnalyticsJS.segmentationSwap(Settings, self.context, {
                from: UtilJS.swapNetworkType(self.account.network),
                to: 'lightning'
            }))
            Settings.registerEvent({ invoice: self.recipient.input })
            self.StackView.view.push(complete_page, { swap: submarine_controller.swap, transaction })
        }
        onFailed: (error) => {
            const segmentation = AnalyticsJS.segmentationSubAccount(Settings, self.account)
            segmentation.error = error
            Analytics.recordEvent('failed_transaction', segmentation)
            self.StackView.view.push(error_page, { error })
        }
    }
    TaskPageFactory {
        title: self.title
        monitor: sign_transaction_controller.monitor
        target: self.StackView.view
        onClosed: self.closeClicked()
    }
    id: self
    title: qsTrId('id_lightning_invoice')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: PrimaryButton {
        id: confirm_button
        enabled: !confirm_button.busy && (controller.transaction?.transaction?.length ?? 0) > 0 && (controller.transaction?.error?.length ?? 0) === 0
        busy: submarine_controller.busy || !(controller.monitor?.idle ?? true) || !(sign_transaction_controller.monitor?.idle ?? true)
        text: qsTrId('id_confirm')
        onClicked: sign_transaction_controller.sign()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        AlertView {
            Layout.bottomMargin: 15
            alert: AnalyticsAlert {
                screen: 'Send'
                network: self.account.network.id
            }
        }
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_account__asset')
        }
        AccountAssetField {
            Layout.fillWidth: true
            id: account_asset_field
            account: self.account
            asset: self.asset
            readonly: true
        }
        FieldTitle {
            text: qsTrId('id_send_to')
        }
        AddressLabel {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            address: self.recipient.input
            padding: 20
            visible: !address_field.visible
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        Bip353Page.Bip353AddressField {
            id: address_field
            address: self.recipient?.bip353 ?? self.recipient?.lnurl?.address ?? ''
            visible: (self.recipient?.lnurl ?? false) || (self.recipient?.bip353 ?? false)
        }
        FieldTitle {
            text: qsTrId('id_amount')
            visible: confirm_button.enabled
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            fiat: self.fiat
            readOnly: true
            session: self.account.session
            unit: self.unit
            visible: confirm_button.enabled
            convert: Convert {
                asset: self.asset
                context: self.context
                input: ({ satoshi: self.amount })
                unit: self.unit
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#A0A0A0'
            text: 'You are paying with Liquid Bitcoin'
            horizontalAlignment: Label.AlignHCenter
            wrapMode: Label.WordWrap
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
            text: self.recipient?.invoice?.description ?? self.recipient?.bolt12?.description ?? ''
            wrapMode: TextArea.Wrap
        }
        VSpacer {
        }
        ErrorPane {
            error: submarine_controller.error || controller.transaction.error
        }
        // Label {
        //     Layout.fillWidth: true
        //     Layout.preferredWidth: 0
        //     text: JSON.stringify(self.recipient, null, 4)
        //     font.pixelSize: 10
        //     wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        // }
        // Label {
        //     Layout.fillWidth: true
        //     Layout.preferredWidth: 0
        //     text: JSON.stringify(submarine_controller.swap.data, null, 4)
        //     font.pixelSize: 10
        //     wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        // }
        ColumnLayout {
            visible: confirm_button.enabled
            spacing: 5
            Fee {
                id: total_fees
                info: true
                text: 'Total Fees'
                convert: Convert {
                    context: self.context
                    account: self.account
                    input: ({ satoshi: Number(submarine_controller.swap?.data?.fee ?? 0) + Number(controller.transaction?.fee ?? 0) })
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
                            text: 'Swap Fee'
                            visible: submarine_controller.swap?.data?.boltz_fee ?? false
                            convert: Convert {
                                context: self.context
                                account: self.account
                                input: ({ satoshi: Number(submarine_controller.swap?.data?.boltz_fee ?? 0) })
                                unit: amount_field.convert.unit
                            }
                        }
                        Label {
                            color: '#FFFFFF'
                            opacity: 0.5
                            text: 'Includes service and Lightning routing'
                            visible: submarine_controller.swap?.data?.boltz_fee ?? false
                        }
                        Fee {
                            Layout.topMargin: 5
                            text: 'Network fee'
                            convert: Convert {
                                context: self.context
                                account: self.account
                                input: ({ satoshi: Number(controller.transaction?.fee ?? 0) + Number(submarine_controller.swap?.data?.fee ?? 0) - Number(submarine_controller.swap?.data?.boltz_fee ?? 0) })
                                unit: amount_field.convert.unit
                            }
                        }
                        Label {
                            color: '#FFFFFF'
                            opacity: 0.5
                            text: 'Network fee to send LBTC on Liquid'
                        }
                    }
                }
            }
            Fee {
                text: 'Recipient receives'
                convert: Convert {
                    context: self.context
                    account: self.account
                    input: ({ satoshi: self.amount })
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
                text: 'Total Spent'
                convert: Convert {
                    context: self.context
                    account: self.account
                    input: ({ satoshi: Number(submarine_controller.swap?.data?.amount ?? 0) + Number(controller.transaction?.fee ?? 0) })
                    unit: amount_field.convert.unit
                }
            }
        }
    }
    Component {
        id: complete_page
        TransactionCompletedPage {
            property var swap
            title: qsTrId('id_success')
            onCloseClicked: self.closeClicked()
        }
    }
    Component {
        id: error_page
        ErrorPage {
            title: self.title
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
