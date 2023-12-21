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
    function pushSelectCoinsPage() {
        self.StackView.view.push(select_coins_page, {
            account: controller.account,
            asset: controller.asset,
            coins: controller.coins,
        })
    }
    function pushSelectFeePage() {
        self.StackView.view.push(select_fee_page, {
            account: controller.account,
            unit: amount_field.unit,
            size: controller.transaction.transaction ? controller.transaction.transaction.length / 2 : 0,
        })
    }

    AnalyticsView {
        name: 'Send'
        active: true
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
                asset: controller.asset
                onClicked: {
                    self.StackView.view.push(account_asset_selector, {
                        context: controller.context,
                        account: controller.account,
                        asset: controller.asset,
                    })
                }
            }
            FieldTitle {
                text: qsTrId('id_manual_coin_selection')
                visible: controller.coins.length > 0
            }
            AbstractButton {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                padding: 20
                visible: controller.coins.length > 0
                background: Rectangle {
                    radius: 5
                    color: '#222226'
                }
                contentItem: RowLayout {
                    spacing: 20
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/coin_selection.svg'
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        text: {
                            let satoshi = 0
                            for (const output of controller.coins) {
                                satoshi += output.data.satoshi
                            }
                            return controller.asset.formatAmount(satoshi, true) + ' (' + controller.coins.length + ' coins)'
                        }
                    }
                    CircleButton {
                        Layout.alignment: Qt.AlignCenter
                        icon.source: 'qrc:/svg2/close.svg'
                        onClicked: controller.coins = []
                    }
                    CircleButton {
                        Layout.alignment: Qt.AlignCenter
                        icon.source: 'qrc:/svg2/edit.svg'
                        onClicked: self.pushSelectCoinsPage()
                    }
                }
                onClicked: self.pushSelectCoinsPage()
            }
            FieldTitle {
                text: 'Enter Address'
            }
            AddressField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: address_field
                text: controller.recipient.address
                // onTextEdited: controller.parseAndUpdate(address_field.text)
                onTextEdited: controller.recipient.address = address_field.text
                focus: true
                error: {
                    if (controller.recipient.address !== '') {
                        const error = controller.transaction?.error
                        if (error === 'id_invalid_address') return error
                    }
                }
            }
            ErrorPane {
                error: address_field.error
            }
            FieldTitle {
                text: qsTrId('Amount')
            }
            AmountField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: amount_field
                account: controller.account
                asset: controller.asset
                onResultChanged: controller.recipient.amount = '' + (amount_field.result.satoshi ?? '')
                error: {
                    const error = controller.transaction?.error
                    if (error === 'id_insufficient_funds') return error
                    if (error === 'id_invalid_amount') return error
                }
            }
            ErrorPane {
                error: amount_field.error
            }
            LinkButton {
                Layout.alignment: Qt.AlignRight
                Layout.bottomMargin: 15
                text: qsTrId('id_send_all')
                enabled: !controller.recipient.greedy
                visible: false
                onClicked: controller.recipient.greedy = true
            }
            Convert {
                id: fee_convert
                account: self.account
                value: controller.transaction.fee ?? 0
                unit: UtilJS.normalizeUnit(amount_field.unit)
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
                    text: fee_convert.unitLabel
                }
            }
            RowLayout {
                Layout.bottomMargin: 20
//                Label {
//                    color: '#6F6F6F'
//                    font.pixelSize: 12
//                    font.weight: 400
//                    text: '~2 hours'
//                }
                LinkButton {
                    text: 'Change speed'
                    onClicked: self.pushSelectFeePage()
                }
                HSpacer {
                }
                Label {
                    color: '#6F6F6F'
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~ ' + fee_convert.fiatLabel
                }
            }
//            Label {
//                Layout.fillWidth: true
//                Layout.preferredWidth: 0
//                font.pixelSize: 10
//                text: JSON.stringify(controller.transaction, null, '  ')
//                wrapMode: Label.Wrap
//                TapHandler {
//                    onTapped: Clipboard.copy(JSON.stringify(controller.transaction, null, '  '))
//                }
//            }
        }
    }
    footerItem: RowLayout {
        spacing: 20
        RegularButton {
            Layout.fillWidth: true
            id: options_button
            implicitWidth: 0
            text: 'Advanced Options'
            onClicked: options_menu.open()
            GMenu {
                id: options_menu
                x: (options_button.width - options_menu.width) * 0.5
                y: -options_menu.height - 8
                pointerX: 0.5
                pointerY: 1
                GMenu.Item {
                    enabled: !controller.account.network.liquid
                    text: qsTrId('id_manual_coin_selection')
                    icon.source: 'qrc:/svg2/coin_selection.svg'
                    onClicked: {
                        options_menu.close()
                        self.pushSelectCoinsPage()
                    }
                }
            }
        }
        PrimaryButton {
            Layout.fillWidth: true
            enabled: (controller.transaction?.transaction?.length ?? 0) > 0
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

    Component {
        id: account_asset_selector
        AccountAssetSelector {
            showCreateAccount: false
            onSelected: (account, asset) => {
                self.StackView.view.pop()
                controller.account = account
                controller.asset = asset
                controller.coins = []
            }
        }
    }

    Component {
        id: send_confirm_page
        SendConfirmPage {
        }
    }

    Component {
        id: select_coins_page
        SelectCoinsView {
            onCoinsSelected: (coins) => {
                self.StackView.view.pop()
                controller.coins = coins
            }
        }
    }

    Component {
        id: select_fee_page
        SelectFeePage {
            onFeeRateSelected: (fee_rate) => {
                controller.feeRate = fee_rate
                self.StackView.view.pop()
            }
        }
    }

    component ErrorPane: Pane {
        required property var error
        id: error_pane
        Layout.fillWidth: true
        Layout.topMargin: -20
        Layout.bottomMargin: 15
        leftPadding: 20
        rightPadding: 20
        bottomPadding: 15
        topPadding: 15
        background: Rectangle {
            color: '#3B080F'
        }
        contentItem: RowLayout {
            spacing: 20
            Image {
                source: 'qrc:/svg2/info_red.svg'
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 12
                font.weight: 600
                color: '#C91D36'
                text: qsTrId(error_pane.error ?? '')
                wrapMode: Label.Wrap
            }
        }
        visible: !!error_pane.error
        z: -1
    }
}
