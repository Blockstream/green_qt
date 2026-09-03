import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    required property Account account
    required property Asset asset
    required property Context context
    required property string input
    required property var recipient
    readonly property var amount: ({ satoshi: self.recipient?.bip21?.amount ?? '0' })
    readonly property bool fixedAmount: self.recipient?.bip21?.amount !== undefined
    readonly property bool coinSelectionSupported: controller.asset?.id === controller.account?.network.policyAsset
    property var available:  self.grossForCoins(controller.coins)
    function grossForCoins(coins) {
        if (coins.length > 0) {
            let satoshi = 0
            for (const output of coins) satoshi += Number(output.data.satoshi ?? 0)
            return { satoshi: String(satoshi) }
        }
        return { satoshi: String(controller.account.json.satoshi[controller.asset?.key ?? 'btc'] ?? 0) }
    }
    function toggleMax() {
        if (self.fixedAmount) return
        if (controller.recipient.greedy) {
            controller.recipient.greedy = false
            amount_field.clearText()
        } else {
            controller.recipient.convert.input = self.grossForCoins(controller.coins)
            controller.recipient.greedy = true
        }
    }
    function pushSelectCoinsPage() {
        self.pushPage(select_coins_page, {
            account: controller.account,
            asset: controller.asset,
            coins: controller.coins,
            unit: amount_field.unit,
        })
    }
    function pushSelectFeePage() {
        self.pushPage(select_fee_page, {
            account: controller.account,
            unit: amount_field.unit,
            size: controller.transaction?.transaction_vsize ?? 0,
        })
    }
    FeeEstimates {
        id: estimates
        session: controller.account.session
    }
    CreateTransactionController {
        id: controller
        context: self.context
        account: self.account
        asset: self.asset
        feeRate: estimates.fees[3]
        recipient.convert.unit: controller.account.session.unit
        recipient.convert.input: self.amount
        recipient.address: self.recipient.address.address ?? ''
    }
    AnalyticsView {
        name: 'Send'
        active: self.StackView.visible
        segmentation: AnalyticsJS.segmentationSubAccount(controller.account)
    }
    StackView.onActivated: amount_field.forceActiveFocus()
    id: self
    title: qsTrId('id_details')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        AlertView {
            Layout.bottomMargin: 20
            alert: AnalyticsAlert {
                screen: 'Send'
                network: controller.account.network.id
            }
        }
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_account__asset')
        }
        AccountAssetField {
            Layout.fillWidth: true
            id: account_asset_field
            account: controller.account
            asset: controller.asset
            readonly: true
            onClicked: {
                if (!account_asset_field.readonly) {
                    self.pushPage(account_asset_selector, {
                        context: controller.context
                    })
                }
            }
        }
        FieldTitle {
            text: qsTrId('id_address')
        }
        AddressLabel {
            Layout.fillWidth: true
            address: controller.recipient.address
            padding: 20
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        ErrorPane {
            Layout.topMargin: -15
            error: {
                if (controller.recipient.address === '') return
                const error = controller.transaction?.error
                if (error === 'id_invalid_address') return error
                if (error === 'id_nonconfidential_addresses_not') return error
                if (error === 'id_assets_cannot_be_used_on_bitcoin') return error
            }
        }
        FieldTitle {
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            // focus: !self.amount
            readOnly: self.fixedAmount
            syncFocusedInput: controller.recipient.greedy
            convert: controller.recipient.convert
            session: controller.account.session
            error: {
                if (amount_field.text.length === 0 && !controller.recipient.greedy) return
                const error = controller.transaction?.error
                if (error === 'id_insufficient_funds') return error
                if (error === 'id_invalid_amount') {
                    if (controller.recipient.convert.result?.sats !== '0') {
                        return error
                    }
                }
                if (error === 'id_amount_below_the_dust_threshold') return error
                if (error === 'Fee change below the dust threshold') {
                    return error
                }
            }
            onCleared: controller.recipient.greedy = false
            onTextEdited: controller.recipient.greedy = false
        }
        ErrorPane {
            Layout.topMargin: -15
            Layout.bottomMargin: 15
            error: amount_field.text.length > 0 || controller.recipient.greedy ? amount_field.error : null
        }
        Convert {
            id: available_convert
            account: controller.account
            asset: controller.asset
            input: self.available
            unit: amount_field.unit
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            InlineButton {
                id: available_button
                enabled: !self.fixedAmount
                contentItem: RowLayout {
                    spacing: 4

                    Label {
                        color: '#929292'
                        font.features: { 'calt': 0, 'zero': 1 }
                        font.pixelSize: 14
                        font.weight: 500
                        text: qsTrId('id_available')
                    }

                    Label {
                        color: Qt.lighter('#00BCFF', available_button.enabled && available_button.hovered ? 1.1 : 1)
                        font.features: { 'calt': 0, 'zero': 1 }
                        font.pixelSize: 14
                        font.weight: 500
                        text: amount_field.fiat && available_convert.fiat.available
                            ? '~ ' + available_convert.fiat.label
                            : available_convert.output.label
                    }
                    Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: 'qrc:/svg2/check-green.svg'
                        visible: controller.recipient.greedy
                    }
                }
                onClicked: self.toggleMax()
            }

            HSpacer {
            }

            InlineButton {
                id: coins_button
                visible: self.coinSelectionSupported
                contentItem: RowLayout {
                    spacing: 2
                    Label {
                        color: controller.coins.length > 0 ? '#FFFFFF' : '#929292'
                        font.pixelSize: 14
                        font.weight: 500
                        text: controller.coins.length === 0
                            ? 'All coins'
                            : controller.coins.length + ' ' + (controller.coins.length === 1 ? 'Coin' : 'Coins')
                    }
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/caret-right.svg'
                    }
                }
                onClicked: self.pushSelectCoinsPage()
            }
        }
        VSpacer {
        }
    }
    footerItem: ColumnLayout {
        spacing: 5
        Convert {
            id: fee_convert
            account: controller.account
            input: ({ satoshi: String(controller.transaction.fee ?? 0) })
            unit: controller.account.session.unit
        }
        Item {
            Layout.minimumHeight: 5
        }
        ErrorPane {
            error: {
                const error = controller.transaction?.error
                if (!error) return null
                if (error === 'id_invalid_replacement_fee_rate'
                    || error === 'Insufficient funds for fees'
                    || error === 'id_rate_limited'
                    || error === 'id_rate_connection_limited'
                    || !error.startsWith('id_')) {
                    return error
                }
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
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 500
                text: fee_convert.output.label
            }
        }
        RowLayout {
            Layout.bottomMargin: 20
            Label {
                color: '#6F6F6F'
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 400
                text: UtilJS.confirmationTime(controller.feeRate, estimates.fees)
                visible: !controller.account.network.liquid
            }
            LinkButton {
                text: qsTrId('id_change_speed')
                visible: !controller.account.network.liquid
                onClicked: self.pushSelectFeePage()
            }
            HSpacer {
            }
            Label {
                font.features: { 'calt': 0, 'zero': 1 }
                color: '#6F6F6F'
                font.pixelSize: 12
                font.weight: 400
                text: '~ ' + fee_convert.fiat.label
            }
        }
        PrimaryButton {
            Layout.fillWidth: true
            enabled: controller.monitor.idle && (controller.transaction?.transaction?.length ?? 0) > 0 && (controller.transaction?.error?.length ?? 0) === 0
            busy: !controller.monitor.idle
            focus: self.amount
            text: qsTrId('id_next')
            onClicked: {
                self.pushPage(send_confirm_page, {
                    recipient: controller.recipient,
                    transaction: controller.transaction,
                    fiat: amount_field.fiat,
                    unit: amount_field.unit,
                    address_input: self.input,
                    bumpRedeposit: false,
                })
            }
        }
    }

    component InlineButton: AbstractButton {
        id: button
        padding: 4
        background: Item {
            Rectangle {
                anchors.fill: parent
                color: '#FFFFFF'
                opacity: 0.1
                radius: 4
                visible: button.hovered
            }
            Rectangle {
                anchors.fill: parent
                border.color: '#00BCFF'
                border.width: 2
                color: 'transparent'
                radius: 4
                visible: button.visualFocus
            }
        }
    }

    Component {
        id: account_asset_selector
        SendAccountAssetSelector {
            onSelected: (account, asset) => {
                self.popPage()
                controller.account = account
                controller.asset = asset
                controller.coins = []
                amount_field.fiat = false
                amount_field.clearText()
            }
        }
    }

    Component {
        id: send_confirm_page
        SendConfirmPage {
            account: controller.account
            asset: controller.asset
            context: self.context
            label: self.recipient?.bip21?.label ?? null
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: select_coins_page
        CoinSelectionPage {
            onCloseClicked: self.closeClicked()
            onCoinsSelected: (coins) => {
                self.popPage()
                if (controller.recipient.greedy) {
                    controller.recipient.convert.input = self.grossForCoins(coins)
                }
                controller.coins = coins
            }
        }
    }

    Component {
        id: select_fee_page
        SelectFeePage {
            previousTransaction: null
            onCloseClicked: self.closeClicked()
            onFeeRateSelected: (fee_rate) => {
                if (controller.recipient.greedy) {
                    controller.recipient.convert.input = self.grossForCoins(controller.coins)
                }
                controller.feeRate = fee_rate
                self.popPage()
            }
        }
    }
}
