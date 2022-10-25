import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtMultimedia 5.13
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

StackView {
    id: stack_view
    required property Account account
    property alias address: address_field.text
    property string address_input
    property Balance balance: asset_field_loader.item ? asset_field_loader.item.balance : null
    property alias sendAll: send_all_button.checked
    property var selectedOutputs: coins_view.selectedOutputs
    property bool manualCoinSelection: coins_combo_box.currentIndex === 1

    property var actions: currentItem.actions
    property var options: currentItem.options

    function parsePayment(url) {
        const payment = WalletManager.parseUrl(url.trim())
        address_field.text = payment.address;
        if (payment.amount) {
            controller.amount = formatAmount(payment.amount * 100000000, false)
        }
        if (payment.message) {
            controller.memo = payment.message
        }
    }

    implicitHeight: stack_view.currentItem.implicitHeight
    implicitWidth: stack_view.currentItem.implicitWidth

    property Item coins_view: SelectCoinsView {
        account: stack_view.account
        property list<Action> actions: [
            Action {
                text: qsTrId('id_done')
                onTriggered: stack_view.pop()
            }
        ]
    }

    Component {
        id: review_view
        ReviewView {}
    }

    initialItem: GridLayout {
        id: setup_view
        property list<Action> actions: [
            Action {
                property bool highlighted: enabled
                text: controller.transaction.error ? qsTrId(controller.transaction.error || '') : qsTrId('id_review')
                enabled: !ledger_support_warning.active && controller.valid && !controller.transaction.error
                onTriggered: stack_view.push(review_view)
            }
        ]

        columns: 2
        rowSpacing: 12
        columnSpacing: 12

        AlertView {
            Layout.columnSpan: 2
            alert: AnalyticsAlert {
                screen: 'Send'
                network: account.wallet.network.id
            }
        }

        ScannerPopup {
            id: scanner_popup
            parent: address_field
            onCodeScanned: {
                parsePayment(code)
                stack_view.address_input = 'scan'
            }
        }

        SectionLabel {
            text: qsTrId('id_address')
        }

        RowLayout {
            GTextField {
                id: address_field
                selectByMouse: true
                Layout.fillWidth: true
                font.pixelSize: 12
                onTextChanged: {
                    parsePayment(text)
                    stack_view.address_input = 'paste'
                }
            }
            ToolButton {
                enabled: scanner_popup.available && !scanner_popup.visible
                icon.source: 'qrc:/svg/qr.svg'
                icon.width: 16
                icon.height: 16
                onClicked: scanner_popup.open()
                ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                ToolTip.text: qsTrId('id_scan_qr_code')
                ToolTip.visible: hovered
            }
            ToolButton {
                icon.source: 'qrc:/svg/paste.svg'
                icon.width: 24
                icon.height: 24
                onClicked: {
                    address_field.clear();
                    address_field.paste();
                    parsePayment(address_field.text)
                    stack_view.address_input = 'paste'
                }
                ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                ToolTip.text: qsTrId('id_paste')
                ToolTip.visible: hovered
            }
        }
        Pane {
            visible: ledger_support_warning.visible
        }
        Loader {
            id: ledger_support_warning
            Layout.fillWidth: true
            active: {
                const device = account.wallet.device
                if (device && device.type === Device.LedgerNanoS && device.appVersion === '1.4.8') {
                    switch (stack_view.balance.asset.id) {
                    case '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d':
                    case 'b00b0ff0b11ebd47f7c6f57614c046dbbd204e84bf01178baf2be3713a206eb7':
                    case '0e99c1a6da379d1f4151fb9df90449d40d0608f6cb33a5bcbfc8c265f42bab0a':
                    case 'd9f6bb516c9f3ab16bed3f3662ae018573ee6b00130f2347a4b735d8e7c4c396':
                    case '3438ecb49fc45c08e687de4749ed628c511e326460ea4336794e1cf02741329e':
                    case 'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2':
                    case 'ffff7e448a09977dbb2d32209154fc4fb44f1e1098d80574f66c3a8e0ab5559f':
                        break;
                    default:
                        return true
                    }
                }
                return false
            }
            visible: active
            sourceComponent: GButton {
                icon.source: 'qrc:/svg/warning.svg'
                baseColor: '#e5e7e9'
                textColor: 'black'
                highlighted: true
                large: true
                text: qsTrId('id_ledger_supports_a_limited_set')
                onClicked: Qt.openUrlExternally('https://docs.blockstream.com/green/hww/hww-index.html#ledger-supported-assets')
                scale: hovered ? 1.01 : 1
                transformOrigin: Item.Center
                Behavior on scale {
                    NumberAnimation {
                        easing.type: Easing.OutBack
                        duration: 400
                    }
                }
            }
        }
        Loader {
            visible: active
            active: wallet.network.liquid
            sourceComponent: SectionLabel {
                text: qsTrId('id_asset')
            }
        }
        Loader {
            id: asset_field_loader
            visible: active
            active: wallet.network.liquid
            Layout.fillWidth: true
            sourceComponent: GComboBox {
                property Balance balance: account.balances[asset_field.currentIndex]
                property Asset asset: balance.asset
                id: asset_field

                model: account.balances
                delegate: AssetDelegate {
                    highlighted: index === asset_field.currentIndex
                    balance: modelData
                    width: parent.width
                }

                leftPadding: 8
                topPadding: 12
                bottomPadding: 12

                contentItem: BalanceItem {
                    balance: account.balances[asset_field.currentIndex]
                }
            }
        }
        SectionLabel {
            text: qsTrId('id_coins')
            visible: !wallet.network.liquid
        }
        RowLayout {
            spacing: 16
            visible: !wallet.network.liquid
            GComboBox {
                Layout.fillWidth: true
                id: coins_combo_box
                model: [
                    { text: qsTrId('Use all available coins'), enabled: true },
                    { text: qsTrId('id_manual_coin_selection'), enabled: true }
                ]
                bottomPadding: 13
                topPadding: 13
                contentItem: RowLayout {
                    spacing: 12
                    Image {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 24
                        source: iconFor(wallet)
                    }
                    Label {
                        text: wallet.network.displayName
                    }
                    Label {
                        Layout.fillWidth: true
                        text: {
                            if (coins_combo_box.currentIndex === 0) return qsTrId('id_all_coins')
                            const count = send_view.selectedOutputs.length
                            if (count === 0) return qsTrId('id_no_coins_selected')
                            return qsTrId('id_d_coins_selected').arg(count)
                        }
                    }
                    Label {
                        text: {
                            if (coins_combo_box.currentIndex === 0) {
                                return stack_view.balance ? stack_view.balance.displayAmount : formatAmount(account.balance)
                            }

                            const asset = stack_view.balance ? stack_view.balance.asset : null
                            var x = 0
                            for (const u of send_view.selectedOutputs) {
                                if (!u.asset || u.asset === asset) {
                                    x += u.data['satoshi']
                                }
                            }
                            return asset ? asset.formatAmount(x, true) : formatAmount(x)
                        }
                    }
                }
                delegate: ItemDelegate {
                    width: coins_combo_box.width
                    text: modelData.text
                    highlighted: ListView.isCurrentItem
                    enabled: modelData.enabled
                }
            }
            GButton {
                large: true
                visible: coins_combo_box.currentIndex === 1
                onClicked: stack_view.push(coins_view)
                text: 'Select Coins'
            }
        }
        SectionLabel {
            text: qsTrId('id_amount')
        }
        RowLayout {
            spacing: 12
            GSwitch {
                Layout.fillWidth: true
                id: send_all_button
                text: qsTrId('id_send_all')
            }
            GTextField {
                id: amount_field
                Layout.fillWidth: true
                enabled: !send_all_button.checked
                horizontalAlignment: TextField.AlignRight
                selectByMouse: true

                placeholderText: controller.effectiveAmount
                text: controller.amount
                onTextChanged: {
                    if (!activeFocus) return;
                    controller.amount = text;
                }
                validator: AmountValidator {
                }
                Label {
                    id: unit
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.baseline: parent.baseline
                    text: wallet.network.liquid ? (balance.asset.id === wallet.network.policyAsset ? wallet.displayUnit : (balance.asset.data.ticker || '')) : wallet.displayUnit
                }
                rightPadding: unit.width + 16
            }

            Label {
                enabled: controller.hasFiatRate
                text: '≈'
            }

            GTextField {
                id: fiat_field
                Layout.fillWidth: true
                enabled: !send_all_button.checked && controller.hasFiatRate && fiatRateAvailable
                horizontalAlignment: TextField.AlignRight
                placeholderText: controller.effectiveFiatAmount
                text: controller.fiatAmount
                selectByMouse: true
                onTextChanged: {
                    if (!activeFocus) return;
                    controller.fiatAmount = text
                }
                validator: AmountValidator {
                }
                Label {
                    id: currency
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.baseline: parent.baseline
                    text: wallet.network.mainnet ? wallet.settings.pricing.currency : 'FIAT'
                }
                rightPadding: currency.width + 16
            }
        }
        SectionLabel {
            text: qsTrId('id_network_fee')
        }
        RowLayout {
            spacing: 12
            FeeComboBox {
                id: fee_combo
                Layout.fillWidth: true
                property var indexes: [3, 12, 24]
                extra: wallet.network.liquid ? [] : [{ text: qsTrId('id_custom') }]
                Component.onCompleted: {
                    currentIndex = wallet.network.liquid ? 0 : indexes.indexOf(wallet.settings.required_num_blocks)
                    controller.feeRate = fee_estimates.fees[blocks]
                }
                onFeeRateChanged: {
                    if (feeRate) {
                        controller.feeRate = feeRate
                    }
                }
                onCurrentIndexChanged: {
                    if (currentIndex === 3) {
                        custom_fee_field.text = Math.round(controller.feeRate / 10 + 0.5) / 100
                    }
                }
            }
            GTextField {
                id: custom_fee_field
                visible: fee_combo.currentIndex === 3
                onTextChanged: {
                    if (fee_combo.currentIndex === 3) {
                        controller.feeRate = Number(text) * 1000
                    }
                }
                horizontalAlignment: TextField.AlignRight
                validator: AmountValidator {
                }
                Label {
                    id: fee_unit
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.baseline: parent.baseline
                    text: 'sat/vB'
                }
                rightPadding: fee_unit.width + 16
                selectByMouse: true
            }
        }
        VSpacer {
            Layout.columnSpan: 2
        }
    }
}
