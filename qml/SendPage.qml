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
                    spacing: 10
                    Convert {
                        id: convert
                        unit: 'sats'
                        account: controller.account
                        asset: controller.asset
                        value: {
                            let satoshi = 0
                            for (const output of controller.coins) {
                                satoshi += output.data.satoshi
                            }
                            return satoshi
                        }
                    }
                    CircleButton {
                        Layout.alignment: Qt.AlignCenter
                        icon.source: 'qrc:/svg2/close.svg'
                        onClicked: controller.coins = []
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        color: '#FFF'
                        font.pixelSize: 16
                        font.weight: 400
                        text: controller.coins.length + ' coins'
                    }
                    ColumnLayout {
                        Label {
                            Layout.alignment: Qt.AlignRight
                            color: '#FFF'
                            font.pixelSize: 12
                            font.weight: 400
                            text: convert.unitLabel
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            color: '#6F6F6F'
                            font.pixelSize: 12
                            font.weight: 400
                            text: convert.fiatLabel
                        }
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
                        if (error === 'id_nonconfidential_addresses_not') return error
                    }
                }
            }
            ErrorPane {
                error: address_field.error
            }
            FieldTitle {
                text: qsTrId('id_amount')
            }
            AmountField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: amount_field
                account: controller.account
                asset: controller.asset
                enabled: !controller.recipient.greedy
                onTextEdited: controller.recipient.greedy = false
                onUnitChanged: controller.recipient.greedy = false
                onFiatChanged: controller.recipient.greedy = false
                onResultChanged: {
                    if (!controller.recipient.greedy) {
                        controller.recipient.amount = String(amount_field.result.satoshi ?? '')
                    }
                }
                error: {
                    const error = controller.transaction?.error
                    if (error === 'id_insufficient_funds') return error
                    if (error === 'id_invalid_amount') return error
                }
            }
            Connections {
                target: controller.recipient
                function onAmountChanged() {
                    if (controller.recipient.greedy) {
                        amount_field.user = false
                        amount_field.setValue(controller.recipient.amount)
                    }
                }
            }
            Binding {
                value: controller.recipient.amount
                target: amount_field
                property: 'text'
                when: controller.recipient.greedy
            }
            ErrorPane {
                error: amount_field.error
            }
            Convert {
                id: available_convert
                unit: 'sats'
                outputUnit: amount_field.unit
                asset: controller.asset
                account: controller.account
                value: String(controller.account.json.satoshi[controller.asset.key])
            }

            RowLayout {
                Layout.bottomMargin: 15
                spacing: 10
                ColumnLayout {
                    Label {
                        Layout.fillWidth: true
                        text: qsTrId('id_available') + ' ' + available_convert.outputUnitLabel
                        font.pixelSize: 14
                        font.weight: 500
                    }
                    Label {
                        color: '#6F6F6F'
                        font.pixelSize: 14
                        font.weight: 500
                        text: '~ ' + available_convert.fiatLabel
                        visible: available_convert.fiat
                    }
                }
//                LinkButton {
//                    Layout.alignment: Qt.AlignRight
//                    text: qsTrId('id_send_all')
//                    enabled: !controller.recipient.greedy
//                    onClicked: {
//                        amount_field.unit = 'sats'
//                        amount_field.fiat = false
//                        amount_field.user = false
//                        controller.recipient.greedy = true
//                    }
//                }
                Label {
                    text: qsTrId('id_send_all')
                    font.pixelSize: 14
                    font.weight: 500
                }
                GSwitch {
                    checked: controller.recipient.greedy
                    onClicked: {
                        if (controller.recipient.greedy) {
                            controller.recipient.greedy = false
                            amount_field.user = true
                            amount_field.setValue(0)
                        } else {
                            amount_field.unit = 'sats'
                            amount_field.fiat = false
                            amount_field.user = false
                            controller.recipient.greedy = true
                        }
                    }
                }
            }

            Convert {
                id: fee_convert
                account: controller.account
                value: controller.transaction.fee ?? 0
                unit: 'sats'
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
                    fiat: amount_field.fiat,
                    unit: amount_field.unit,
                })
            }
        }
    }

    Component {
        id: account_asset_selector
        SendAccountAssetSelector {
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

    component ErrorPane: Collapsible {
        required property var error
        Layout.fillWidth: true
        Layout.topMargin: -30
        Layout.bottomMargin: 15
        id: error_pane
        animationVelocity: 300
        contentWidth: error_pane.width
        contentHeight: pane.height
        collapsed: !error_pane.error
        z: -1
        Pane {
            id: pane
            leftPadding: 10
            rightPadding: 10
            bottomPadding: 15
            topPadding: 25
            width: error_pane.width
            background: Rectangle {
                color: '#3B080F'
                radius: 5
            }
            contentItem: RowLayout {
                spacing: 10
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
        }
    }
}
