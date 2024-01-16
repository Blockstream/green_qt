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
    FeeEstimates {
        id: estimates
        session: self.account.session
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
        recipient.convert.unit: self.account.session.unit
        feeRate: estimates.fees[24] ?? 0
    }
    id: self
    title: qsTrId('id_send')
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
                        asset: controller.recipient.convert.asset,
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
                        account: controller.account
                        asset: controller.asset
                        input: {
                            let satoshi = 0
                            for (const output of controller.coins) {
                                satoshi += output.data.satoshi
                            }
                            return { satoshi: String(satoshi) }
                        }
                        unit: controller.account.session.unit
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
                            text: convert.output.label
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            color: '#6F6F6F'
                            font.pixelSize: 12
                            font.weight: 400
                            text: convert.fiat.label
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
                onTextEdited: controller.recipient.address = address_field.text
                onCodeScanned: (code) => controller.recipient.address = code
                focus: true
                error: {
                    if (controller.recipient.address === '') return
                    const error = controller.transaction?.error
                    if (error === 'id_invalid_address') return error
                    if (error === 'id_nonconfidential_addresses_not') return error
                    if (error === 'id_assets_cannot_be_used_on_bitcoin') return error
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
                readOnly: controller.recipient.greedy
                convert: controller.recipient.convert
                unit: self.account.session.unit
                error: {
                    const error = controller.transaction?.error
                    if (error === 'id_insufficient_funds') return error
                    if (error === 'id_invalid_amount') {
                        const satoshi = controller.transaction?.addressee?.[0]?.satoshi ?? 0
                        if (satoshi > 0) return error
                    }
                }
            }
            ErrorPane {
                error: amount_field.error
            }
            Convert {
                id: available_convert
                account: controller.account
                asset: controller.asset
                input: ({ satoshi: String(controller.account.json.satoshi[controller.asset.key]) })
                unit: controller.recipient.convert.unit
            }
            RowLayout {
                Layout.bottomMargin: 15
                spacing: 10
                ColumnLayout {
                    Label {
                        Layout.fillWidth: true
                        text: qsTrId('id_available') + ' ' + available_convert.output.label
                        font.pixelSize: 14
                        font.weight: 500
                    }
                    Label {
                        color: '#6F6F6F'
                        font.pixelSize: 14
                        font.weight: 500
                        text: '~ ' + available_convert.fiat.label
                        visible: available_convert.fiat.available
                    }
                }
                Label {
                    text: qsTrId('id_send_all')
                    font.pixelSize: 14
                    font.weight: 500
                }
                GSwitch {
                    checked: controller.recipient.greedy
                    onClicked: controller.recipient.greedy = !controller.recipient.greedy
                }
            }
            Convert {
                id: fee_convert
                account: controller.account
                input: ({ satoshi: String(controller.transaction.fee ?? 0) })
                unit: controller.account.session.unit
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
                    text: fee_convert.output.label
                }
            }
            RowLayout {
                Layout.bottomMargin: 20
                Label {
                    color: '#6F6F6F'
                    font.pixelSize: 14
                    font.weight: 400
                    text: {
                        if (controller.feeRate <= estimates.fees[24]) {
                            return qsTrId('id_4_hours')
                        }
                        if (controller.feeRate <= estimates.fees[12]) {
                            return qsTrId('id_2_hours')
                        }
                        if (controller.feeRate <= estimates.fees[3]) {
                            return qsTrId('id_1030_minutes')
                        }
                        return qsTrId('id_custom')
                    }
                    visible: !controller.account.network.liquid
                }
                LinkButton {
                    text: 'Change speed'
                    visible: !controller.account.network.liquid
                    onClicked: self.pushSelectFeePage()
                }
                HSpacer {
                }
                Label {
                    color: '#6F6F6F'
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~ ' + fee_convert.fiat.label
                }
            }
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
            onClosed: self.closed()
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
