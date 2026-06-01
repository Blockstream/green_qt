import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import 'util.js' as UtilJS

StackViewPage {
    required property Context context
    property Account sendAccount
    property string sendNetworkKey: 'bitcoin'
    property string receiveNetworkKey: 'liquid'
    property bool sendActive: true
    property real feeRate: fee_estimates.fees[3] ?? 0
    property var error: {
        const send_amount = Number(controller.quote?.send_amount ?? 0)
        if (self.sendActive && send_field.amountField.text.length === 0) {
            return null
        }
        if (!self.sendActive && receive_field.amountField.text.length === 0) {
            return null
        }
        let value = Number(controller.quote?.min ?? 0)
        if (send_amount < value) {
            return { code: 'id_amount_below_minimum_allowed', value }
        }
        value = Number(controller.quote?.max ?? 0)
        if (send_amount > value) {
            return { code: 'id_amount_above_maximum_allowed', value }
        }
        value = send_field?.account.json.satoshi[send_field.asset?.key] ?? 0
        if (send_amount > value) {
            return { code: 'id_insufficient_funds', value }
        }
    }
    Component.onCompleted: {
        controller.invalidate()
        const accounts = UtilJS.accounts(self.context)
        receive_field.account = accounts.find(account => account.network.key === controller.receiveNetworkKey) ?? null
        send_field.account = self.sendAccount ?? accounts.find(account => account.network.key === controller.sendNetworkKey) ?? null
    }
    SwapQuoteController {
        id: controller
        context: self.context
        sendNetworkKey: self.sendNetworkKey
        receiveNetworkKey: self.receiveNetworkKey
        onQuoteChanged: {
            if (self.sendActive) {
                receive_field.convert.input = { satoshi: controller.quote.receive_amount }
            } else {
                send_field.convert.input = { satoshi: controller.quote.send_amount }
            }
        }
    }
    FeeEstimates {
        id: fee_estimates
        session: send_field.account.session
        onSessionChanged: self.feeRate = Qt.binding(() => fee_estimates.fees[3] ?? 0)
    }
    AnalyticsView {
        name: 'Swap'
        active: true
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
    }
    id: self
    title: qsTrId('id_details')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        Pane {
            Layout.fillWidth: true
            focus: true
            padding: 7
            background: Rectangle {
                border.color: '#C91D36'
                border.width: 2
                color: '#3B080F'
                radius: 5
                visible: error_pane.expanded
            }
            contentItem: ColumnLayout {
                spacing: 1
                OperandField {
                    id: send_field
                    focus: true
                    label: 'From'
                    showSelectAccount: UtilJS.accounts(self.context).filter(account => account.network.key === controller.sendNetworkKey).length > 1
                    convert.onResultChanged: {
                        if (self.sendActive) {
                            controller.send(send_field.convert.result?.satoshi ?? '')
                        }
                    }
                    onActivated: self.sendActive = true
                    amountField.onFiatChanged: {
                        if (self.sendActive) {
                            if (send_field.amountField.fiat) {
                                receive_field.amountField.setFiat()
                            } else {
                                receive_field.amountField.setUnit(send_field.amountField.unit)
                            }
                        }
                    }
                    amountField.onUnitChanged: {
                        if (self.sendActive) {
                            receive_field.amountField.setUnit(send_field.amountField.unit)
                        }
                    }
                }
                CircleButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: -14
                    Layout.bottomMargin: -14
                    id: invert_button
                    icon.source: 'qrc:/fafafa/20/arrows-down-up.svg'
                    padding: 5
                    z: 1
                    background: Rectangle {
                        color: Qt.lighter('#181818', invert_button.hovered ? 1.2 : 1)
                        radius: 5
                        border.color: invert_button.visualFocus ? '#00BCFF' : '#262626'
                        border.width: invert_button.visualFocus ? 2 : 1
                    }
                    onClicked: {
                        const account = send_field.account
                        send_field.account = receive_field.account
                        receive_field.account = account
                        controller.swapNetworks()
                    }
                }
                OperandField {
                    id: receive_field
                    label: 'To'
                    showSelectAccount: UtilJS.accounts(self.context).filter(account => account.network.key === controller.receiveNetworkKey).length > 1
                    convert.onResultChanged: {
                        if (!self.sendActive) {
                            controller.receive(receive_field.convert.result?.satoshi ?? '')
                        }
                    }
                    onActivated: self.sendActive = false
                    amountField.onFiatChanged: {
                        if (!self.sendActive) {
                            if (receive_field.amountField.fiat) {
                                send_field.amountField.setFiat()
                            } else {
                                send_field.amountField.setUnit(receive_field.amountField.unit)
                            }
                        }
                    }
                    amountField.onUnitChanged: {
                        if (!self.sendActive) {
                            send_field.amountField.setUnit(receive_field.amountField.unit)
                        }
                    }
                }
                Convert {
                    id: error_value_convert
                    asset: send_field.asset
                    context: self.context
                    input: ({ satoshi: String(self.error?.value ?? 0) })
                    unit: send_field.convert.unit
                }
                ErrorPane {
                    id: error_pane
                    error: self.error ? qsTrId(self.error?.code) + ' - ' + (send_field.amountField.fiat ? '~ ' + error_value_convert.fiat.label : error_value_convert.output.label) : null
                }
            }
        }
        VSpacer {
        }
        RowLayout {
            visible: !send_field.account.network.liquid
            LinkButton {
                text: qsTrId('id_change_speed')
                visible: !send_field.account.network.liquid
                onClicked: {
                    self.StackView.view.push(select_fee_page, {
                        account: send_field.account,
                        unit: send_field.amountField.unit,
                    })
                }
            }
            Label {
                Layout.fillWidth: true
                color: '#6F6F6F'
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 400
                text: '(' + UtilJS.confirmationTime(self.feeRate, fee_estimates.fees) + ')'
            }
            Label {
                color: '#6F6F6F'
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 400
                text: UtilJS.formatFeeRate(self.feeRate, send_field.account.network)
            }
        }
    }
    footerItem: PrimaryButton {
        enabled: !self.error && Number(controller.quote?.receive_amount) > 0
        text: qsTrId('id_next')
        onClicked: {
            Analytics.recordEvent('swap_initiate', AnalyticsJS.segmentationSwap(Settings, self.context, { 
                from: UtilJS.swapNetworkType(send_field.account.network), 
                to: UtilJS.swapNetworkType(receive_field.account.network)
            }))
            self.StackView.view.push(chain_swap_review_page, {
                feeRate: self.feeRate,
                quote: controller.quote
            })
        }
    }
    component OperandField: Pane {
        signal activated()
        property Account account
        required property string label
        readonly property Asset asset: field.account ? self.context.getOrCreateAsset(field.account.network.policyAsset) : null
        readonly property AmountField amountField: amount_field
        required property bool showSelectAccount
        readonly property Convert convert: Convert {
            asset: field.asset
            context: self.context
            unit: UtilJS.unit(self.context)
        }
        Convert {
            id: available_convert
            asset: field.asset
            context: self.context
            input: ({ satoshi: String(field.account.json.satoshi[field.asset?.key]) })
            unit: field.convert.unit
        }
        Layout.fillWidth: true
        id: field
        topPadding: 16
        leftPadding: 16
        bottomPadding: 16
        rightPadding: 16
        background: Item {
            Rectangle {
                anchors.fill: parent
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 5
                visible: amount_field.visualFocus
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: amount_field.visualFocus ? 4 : 0
                color: '#181818'
                radius: amount_field.visualFocus ? 1 : 5
                border.color: '#262626'
                border.width: !amount_field.visualFocus ? 1 : 0
            }
        }
        contentItem: ColumnLayout {
            spacing: 20
            RowLayout {
                Label {
                    color: '#A0A0A0'
                    text: field.label
                }
                LinkButton {
                    Layout.fillWidth: true
                    text: UtilJS.accountName(field.account)
                    visible: field.showSelectAccount
                    onClicked: {
                        self.StackView.view.push(account_selector_page, {
                            accounts: UtilJS.accounts(self.context).filter(account => account.network.key === field.account.network.key),
                            asset: field.asset,
                            field,
                        })
                    }
                }
                HSpacer {
                }
            }
            AmountField {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                id: amount_field
                background: null
                focus: true
                convert: field.convert
                session: field.account?.session
                font.pixelSize: 18
                font.weight: 500
                horizontalAlignment: TextInput.AlignRight
                embed: true
                onActiveFocusChanged: {
                    if (amount_field.activeFocus) {
                        field.activated()
                    }
                }
                leftItem: RowLayout {
                    spacing: 8
                    AssetIcon {
                        size: 18
                        asset: field.asset
                    }
                    Label {
                        font.pixelSize: 18
                        font.weight: 500
                        text: field.asset.name
                    }
                }
                spacing: 20
                thirdLabel: qsTrId('id_available') + ' ' + (amount_field.fiat ? '~ ' + available_convert.fiat.label : available_convert.output.label)
            }
        }
    }
    Component {
        id: account_selector_page
        AccountSelectorPage {
            required property OperandField field
            id: page
            context: self.context
            message: ''
            onAccountClicked: (account) => {
                field.account = account
                page.StackView.view.pop()
            }
        }
    }
    Component {
        id: select_fee_page
        SelectFeePage {
            previousTransaction: null
            size: 0
            onCloseClicked: self.closeClicked()
            onFeeRateSelected: (fee_rate) => {
                self.feeRate = fee_rate
                self.StackView.view.pop()
            }
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
        id: chain_swap_review_page
        ChainSwapReviewPage {
            context: self.context
            receiveAccount: receive_field.account
            receiveAsset: receive_field.asset
            sendAccount: send_field.account
            sendAsset: send_field.asset
            fiat: receive_field.amountField.fiat
            unit: receive_field.amountField.unit
            onCloseClicked: self.closeClicked()
        }
    }
}
