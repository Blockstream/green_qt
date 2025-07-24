import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal closed()
    required property Context context
    required property Account account
    required property Asset asset
    required property Recipient recipient
    required property bool fiat
    required property string unit
    required property var transaction
    required property bool bumpRedeposit
    property bool note: controller.memo.length > 0
    property string address_input
    StackView.onActivated: controller.cancel()
    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: self.StackView.view
        onClosed: self.closed()
    }
    SignTransactionController {
        id: controller
        context: self.context
        account: self.account
        transaction: self.transaction
        memo: note_text_area.text
        onTransactionCompleted: transaction => {
            Analytics.recordEvent('send_transaction', AnalyticsJS.segmentationTransaction(Settings, self.account, {
                address_input: self.address_input,
                transaction_type: self.transaction.previous_transaction ? 'bump' : 'send',
                with_memo: controller.memo.length > 0,
            }))
            if (self.recipient.greedy) {
                Analytics.recordEvent('account_emptied', AnalyticsJS.segmentationWalletActive(Settings, self.context))
            }
            // TODO: should replace but we must cut dependency to the current view
            self.StackView.view.push(transaction_completed_page, { transaction })
        }
        onFailed: (error) => {
            const segmentation = AnalyticsJS.segmentationSubAccount(Settings, self.account)
            segmentation.error = error
            Analytics.recordEvent('failed_transaction', segmentation)
            self.StackView.view.push(error_page, { error })
        }
    }
    AnalyticsView {
        name: 'SendConfirm'
        active: self.StackView.visible
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.account)
    }
    id: self
    title: qsTrId('id_confirm_transaction')
    rightItem: CloseButton {
        onClicked: self.closed()
    }
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
            AlertView {
                Layout.bottomMargin: 15
                alert: AnalyticsAlert {
                    screen: 'SendConfirm'
                    network: self.account.network.id
                }
            }
            FieldTitle {
                text: qsTrId('id_account__asset')
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
                visible: !self.bumpRedeposit
            }
            AddressLabel {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                address: self.recipient.address
                background: Rectangle {
                    color: '#222226'
                    radius: 5
                }
                padding: 20
                visible: !self.bumpRedeposit
            }
            FieldTitle {
                text: qsTrId('id_amount')
                visible: !self.bumpRedeposit
            }
            AmountField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                unit: self.unit
                fiat: self.fiat
                convert: self.recipient.convert
                readOnly: true
                visible: !self.bumpRedeposit
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
                text: self.transaction.previous_transaction?.memo ?? ''
                visible: self.note
                wrapMode: TextArea.Wrap
                background: Rectangle {
                    color: Qt.lighter('#222226', note_text_area.hovered ? 1.2 : 1)
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
            input: ({ satoshi: String(self.transaction.fee) })
            unit: self.account.session.unit
        }
        Convert {
            id: total_convert
            account: self.account
            input: {
                const network = self.account.network
                const total = self.transaction.fee - (self.transaction.satoshi[network.liquid ? network.policyAsset : 'btc'] ?? 0)
                return { satoshi: String(total) }
            }
            unit: self.account.session.unit
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
                    text: fee_convert.output.label
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    opacity: 0.5
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~ ' + fee_convert.fiat.label
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
                    text: total_convert.output.label
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 500
                    opacity: 0.5
                    text: '~ ' + total_convert.fiat.label
                }
            }
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 200
            Layout.topMargin: 20
            enabled: controller.monitor?.idle ?? true
            busy: !(controller.monitor?.idle ?? true)
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
        id: error_page
        ErrorPage {
            title: self.title
        }
    }

    Component {
        id: transaction_completed_page
        TransactionCompletedPage {
            leftItem: Item {
            }
            onClosed: self.closed()
        }
    }
}
