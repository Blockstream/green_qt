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
            unit: controller.account.session.unit,
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
    }
    AnalyticsView {
        name: 'Send'
        active: self.StackView.visible
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.account)
    }
    id: self
    title: qsTrId('id_redeposit')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
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
                text: qsTrId('id_account__asset')
            }
            AccountAssetField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: account_asset_field
                account: controller.account
                asset: self.context.getOrCreateAsset('btc')
                readonly: true
            }
        }
    }
    footerItem: ColumnLayout {
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
                if (error === 'id_insufficient_funds') return error
                if (error === 'Fee change below the dust threshold') {
                    return error
                }
            }
        }
        RowLayout {
            spacing: 20
            PrimaryButton {
                Layout.fillWidth: true
                enabled: (controller.transaction?.transaction?.length ?? 0) > 0
                implicitWidth: 0
                text: qsTrId('id_next')
                onClicked: {
                    self.StackView.view.push(redeposit_confirm_page, {
                        context: self.context,
                        account: controller.account,
                        transaction: controller.transaction,
                    })
                }
            }
        }
    }

    Component {
        id: redeposit_confirm_page
        RedepositConfirmPage {
            onCloseClicked: self.closeClicked()
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
}
