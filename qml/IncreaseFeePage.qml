import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Account account
    required property Asset asset
    required property AccountTransaction transaction

    readonly property bool bumpRedeposit: self.transaction?.type === AccountTransaction.Redeposit
    readonly property bool coinSelectionSupported: controller.asset?.id === controller.account?.network.policyAsset

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
        previousTransaction: self.transaction
        recipient.convert.unit: controller.account.session.unit
    }
    id: self
    title: qsTrId('id_increase_fee')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        AlertView {
            Layout.bottomMargin: 15
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
            account: controller.account
            asset: controller.asset
            readonly: true
        }
        FieldTitle {
            text: qsTrId('id_address')
            visible: !self.bumpRedeposit
        }
        AddressLabel {
            Layout.fillWidth: true
            address: controller.recipient.address
            visible: !self.bumpRedeposit
            padding: 20
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        ErrorPane {
            Layout.topMargin: -15
            visible: !self.bumpRedeposit
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
            visible: !self.bumpRedeposit
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            visible: !self.bumpRedeposit
            readOnly: true
            convert: controller.recipient.convert
            session: controller.account.session
            error: {
                if (amount_field.text.length === 0) return
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
        }
        ErrorPane {
            Layout.topMargin: -15
            Layout.bottomMargin: 15
            visible: !self.bumpRedeposit
            error: amount_field.text.length > 0 ? amount_field.error : null
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            HSpacer {
            }

            AbstractButton {
                id: coins_button
                padding: 4
                visible: self.coinSelectionSupported
                background: Item {
                    Rectangle {
                        anchors.fill: parent
                        color: '#FFFFFF'
                        opacity: 0.1
                        radius: 4
                        visible: coins_button.hovered
                    }
                    Rectangle {
                        anchors.fill: parent
                        border.color: '#00BCFF'
                        border.width: 2
                        color: 'transparent'
                        radius: 4
                        visible: coins_button.visualFocus
                    }
                }
                contentItem: RowLayout {
                    spacing: 2
                    Label {
                        color: controller.coins.length > 0 ? '#FFFFFF' : '#929292'
                        font.pixelSize: 14
                        font.weight: 500
                        text: controller.coins.length === 0
                            ? 'Additional coins'
                            : controller.coins.length + ' ' + (controller.coins.length === 1 ? 'Additional Coin' : 'Additional Coins')
                    }
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/caret-right.svg'
                    }
                }
                onClicked: {
                    self.pushPage(select_coins_page, {
                        account: controller.account,
                        asset: controller.asset,
                        coins: controller.coins,
                        unit: amount_field.unit,
                    })
                }
            }
        }
        VSpacer {
        }
    }
    footerItem: ColumnLayout {
        spacing: 5
        Convert {
            id: previous_fee_convert
            account: controller.account
            input: ({ satoshi: String(self.transaction?.data?.fee ?? 0) })
            unit: controller.account.session.unit
        }
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
                text: qsTrId('id_previous_fee')
            }
            HSpacer {
            }
            Label {
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 500
                text: previous_fee_convert.output.label
            }
        }
        RowLayout {
            Layout.bottomMargin: 20
            HSpacer {
            }
            Label {
                font.features: { 'calt': 0, 'zero': 1 }
                color: '#6F6F6F'
                font.pixelSize: 12
                font.weight: 400
                text: '~ ' + previous_fee_convert.fiat.label
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
                onClicked: {
                    self.pushPage(select_fee_page, {
                        account: controller.account,
                        unit: amount_field.unit,
                        size: controller.transaction?.transaction_vsize ?? 0,
                    })
                }
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
            text: qsTrId('id_next')
            onClicked: {
                self.pushPage(send_confirm_page, {
                    recipient: controller.recipient,
                    transaction: controller.transaction,
                    fiat: amount_field.fiat,
                    unit: amount_field.unit,
                    address_input: '',
                    bumpRedeposit: self.bumpRedeposit,
                })
            }
        }
    }

    Component {
        id: send_confirm_page
        SendConfirmPage {
            account: controller.account
            asset: controller.asset
            context: self.context
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: select_coins_page
        CoinSelectionPage {
            additionalCoins: true
            onCloseClicked: self.closeClicked()
            onCoinsSelected: (coins) => {
                self.popPage()
                controller.coins = coins
            }
        }
    }

    Component {
        id: select_fee_page
        SelectFeePage {
            previousTransaction: self.transaction
            onCloseClicked: self.closeClicked()
            onFeeRateSelected: (fee_rate) => {
                controller.feeRate = fee_rate
                self.popPage()
            }
        }
    }
}
