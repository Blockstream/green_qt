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
    required property string address
    required property string input
    required property var amount
    required property Asset asset
    property url url
    property var available: {
        if (controller.coins.length > 0) {
            let satoshi = 0
            for (const output of controller.coins) {
                satoshi += output.data.satoshi
            }
            return { satoshi: String(satoshi) }
        } else {
            return { satoshi: String(controller.account.json.satoshi[controller.asset?.key ?? 'btc']) }
        }
    }
    function pushSelectCoinsPage() {
        self.StackView.view.push(select_coins_page, {
            account: controller.account,
            asset: controller.asset,
            coins: controller.coins,
            unit: amount_field.unit,
        })
    }
    function pushSelectFeePage() {
        self.StackView.view.push(select_fee_page, {
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
        recipient.convert.unit: controller.account.session.unit
        recipient.convert.input: self.amount
        recipient.address: self.address
    }
    AnalyticsView {
        name: 'Send'
        active: self.StackView.visible
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, controller.account)
    }
    id: self
    title: qsTrId('id_send')
    rightItem: CloseButton {
        onClicked: self.closed()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 10
        AlertView {
            alert: AnalyticsAlert {
                screen: 'Send'
                network: controller.account.network.id
            }
        }
        FieldTitle {
            text: qsTrId('id_account__asset')
        }
        AccountAssetField {
            Layout.bottomMargin: 15
            Layout.fillWidth: true
            id: account_asset_field
            account: controller.account
            asset: controller.asset
            readonly: true
            onClicked: {
                if (!account_asset_field.readonly) {
                    self.StackView.view.push(account_asset_selector, {
                        context: controller.context
                    })
                }
            }
        }
        FieldTitle {
            text: qsTrId('id_manual_coin_selection')
            visible: controller.coins.length > 0
        }
        AbstractButton {
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
                    input: self.available
                    unit: amount_field.unit
                }
                CircleButton {
                    Layout.alignment: Qt.AlignCenter
                    icon.source: 'qrc:/svg2/x-circle.svg'
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
            text: qsTrId('id_address')
        }
        AddressLabel {
            Layout.bottomMargin: 15
            Layout.fillWidth: true
            address: controller.recipient.address
            topPadding: 14
            bottomPadding: 13
            leftPadding: 15
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        ErrorPane {
            Layout.topMargin: -30
            Layout.bottomMargin: 15
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
            Layout.bottomMargin: 15
            Layout.fillWidth: true
            id: amount_field
            focus: !self.amount
            readOnly: false
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
            Layout.topMargin: -30
            Layout.bottomMargin: 15
            error: amount_field.text.length > 0 || controller.recipient.greedy ? amount_field.error : null
        }
        Convert {
            id: available_convert
            account: controller.account
            asset: controller.asset
            input: self.available
            unit: controller.recipient.convert.unit
        }
        RowLayout {
            Layout.bottomMargin: 15
            spacing: 10
            Label {
                Layout.fillWidth: true
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 500
                opacity: 0.4
                text: qsTrId('id_available') + ' ' + (amount_field.fiat ? '~ ' + available_convert.fiat.label : available_convert.output.label)
                visible: !amount_field.fiat || available_convert.fiat.available
            }
            LinkButton {
                Layout.alignment: Qt.AlignTop
                enabled: !controller.recipient.greedy
                font.pixelSize: 14
                font.weight: 600
                text: qsTrId('id_send_all')
                onClicked: controller.recipient.greedy = true
            }
        }
        VSpacer {
        }
    }
    footerItem: ColumnLayout {
        Convert {
            id: fee_convert
            account: controller.account
            input: ({ satoshi: String(controller.transaction.fee ?? 0) })
            unit: controller.account.session.unit
        }
        ErrorPane {
            error: {
                const error = controller.transaction?.error
                if (error === 'id_invalid_replacement_fee_rate') return error
                if (error === 'Insufficient funds for fees') return error
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
                text: {
                    if (controller.feeRate < estimates.fees[24]) {
                        return qsTrId('id_custom')
                    }
                    if (controller.feeRate < estimates.fees[12]) {
                        return qsTrId('id_4_hours')
                    }
                    if (controller.feeRate < estimates.fees[3]) {
                        return qsTrId('id_2_hours')
                    }
                    return qsTrId('id_1030_minutes')
                }
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
        LinkButton {
            Layout.bottomMargin: 20
            enabled: controller.asset?.id === controller.account.network.policyAsset
            text: qsTrId('id_manual_coin_selection')
            onClicked: self.pushSelectCoinsPage()
        }
        PrimaryButton {
            Layout.fillWidth: true
            enabled: controller.monitor.idle && (controller.transaction?.transaction?.length ?? 0) > 0 && (controller.transaction?.error?.length ?? 0) === 0
            busy: !controller.monitor.idle
            focus: self.amount
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
                    address_input: self.input,
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
                amount_field.fiat = false
                amount_field.clearText()
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
            topPadding: error_pane.Layout.topMargin !== 0 ? 25 : 15
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
