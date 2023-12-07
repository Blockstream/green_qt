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
    property Asset asset
    AnalyticsView {
        name: 'Send'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSubAccount(self.account)
    }
    CreateTransactionController {
        id: controller
        context: self.context
        account: self.account
        asset: self.asset
    }
    id: self
    title: qsTrId('id_send')
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
                    screen: 'Send'
                    network: account.network.id
                }
            }
            FieldTitle {
                text: 'Asset & Account'
            }
            AccountAssetField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                account: controller.account
                asset: self.asset
                onClicked: {
                    self.StackView.view.push(account_asset_selector, {
                        context: controller.context,
                        account: controller.account,
                        asset: controller.asset,
                    })
                }
            }
            FieldTitle {
                text: 'Enter Address'
            }
            ScannerPopup {
                id: scanner_popup
                parent: address_field
                onCodeScanned: (code) => controller.parseAndUpdate(code)
            }
            AddressField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: address_field
                text: controller.recipient.address
                // onTextEdited: controller.parseAndUpdate(address_field.text)
                onTextEdited: {
                    controller.recipient.address = address_field.text
                    controller.invalidate()
                }
                focus: true
            }
            FieldTitle {
                text: qsTrId('Amount')
            }
            AmountField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: amount_field
                text: controller.recipient.amount
                onTextEdited: {
                    controller.recipient.greedy = false
                    controller.recipient.amount = amount_field.text
                    controller.invalidate()
                }
            }
            LinkButton {
                Layout.alignment: Qt.AlignRight
                text: qsTrId('id_send_all')
                enabled: !controller.recipient.greedy
                onClicked: {
                    controller.recipient.greedy = true
                    controller.invalidate()
                }
            }
            RowLayout {
                Label {
                    font.pixelSize: 14
                    font.weight: 500
                    text: qsTrId('id_network_fee')
                }
                HSpacer {
                }
                Label {
                    font.pixelSize: 14
                    font.weight: 500
                    text: '0,000012 L-BTC'
                }
            }
            RowLayout {
                Layout.bottomMargin: 20
                Label {
                    color: '#6F6F6F'
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~2 hours'
                }
                LinkButton {
                    text: 'Change speed'
                }
                HSpacer {
                }
                Label {
                    color: '#6F6F6F'
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~2,23 USD'
                }
            }
        }
    }
    footer: Pane {
        background: null
        padding: self.padding
        bottomPadding: 20
        contentItem: RowLayout {
            Layout.bottomMargin: 65
            spacing: 20
            RegularButton {
                Layout.fillWidth: true
                implicitWidth: 0
                text: 'Advanced Options'
            }
            PrimaryButton {
                Layout.fillWidth: true
                implicitWidth: 0
                text: qsTrId('id_next')
                onClicked: {
                    self.StackView.view.push(send_confirm_page, {
                        context: self.context,
                        account: controller.account,
                        asset: controller.asset,
                        recipient: controller.recipient,
                        transaction: controller.transaction,
                    })
                }
            }
        }
    }

    Component {
        id: account_asset_selector
        AccountAssetSelector {
            showCreateAccount: false
            onSelected: (account, asset) => {
                self.StackView.view.pop()
                controller.account = account
                controller.asset = asset
                controller.invalidate()
            }
        }
    }

    Component {
        id: send_confirm_page
        SendConfirmPage {
        }
    }
}
