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
    property Asset asset: self.context.getOrCreateAsset('btc')

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
            previousTransaction: null
        })
    }
    FeeEstimates {
        id: estimates
        session: self.account.session
    }
    RedepositController {
        id: controller
        context: self.context
        account: self.account
        asset: self.asset
        recipient.convert.unit: self.account.session.unit
        feeRate: estimates.fees[24] ?? 0
    }
    AnalyticsView {
        name: 'Send'
        active: self.StackView.visible
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.account)
    }
    id: self
    title: qsTrId('Redeposit')
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
                    screen: 'Redeposit'
                    network: self.account.network.id
                }
            }
            FieldTitle {
                text: 'Asset & Account'
            }
            AccountAssetField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: account_asset_field
                account: controller.account
                asset: controller.asset
                readonly: true
            }
            FieldTitle {
                text: qsTrId('id_amount')
            }
            AmountField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: amount_field
                readOnly: true
                convert: controller.recipient.convert
                unit: self.account.session.unit
                error: {
                    const error = controller.transaction?.error
                    if (error === 'id_insufficient_funds') return error
                    if (error === 'id_invalid_amount') {
                        if (controller.recipient.convert.result?.sats !== '0') {
                            return error
                        }
                    }
                }
            }
            ErrorPane {
                Layout.topMargin: -30
                Layout.bottomMargin: 15
                error: amount_field.error
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
                    text: qsTrId('id_change_speed')
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
            ErrorPane {
                error: {
                    const error = controller.transaction?.error
                    if (error === 'id_invalid_replacement_fee_rate') return error
                    if (error === 'Insufficient funds for fees') return error
                }
            }
        }
    }
    footerItem: RowLayout {
        spacing: 20
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
