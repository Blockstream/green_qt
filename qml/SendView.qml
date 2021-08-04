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
    property Balance balance: asset_field_loader.item ? asset_field_loader.item.balance : null
    property alias sendAll: send_all_button.checked
    property var selectedOutputs: coins_view.selectedOutputs
    property bool manualCoinSelection: coins_combo_box.currentIndex === 1

    property var actions: currentItem.actions
    property var options: currentItem.options

    Component {
        id: scanner_view
        ScannerView {
            implicitHeight: Math.max(setup_view.implicitHeight, 300)
            implicitWidth: Math.max(setup_view.implicitWidth, 300)
            onCancel: stack_view.pop();
            onCodeScanned: {
                address_field.text = WalletManager.parseUrl(code).address;
                stack_view.pop();
            }
        }
    }

    implicitHeight: setup_view.implicitHeight
    implicitWidth: setup_view.implicitWidth

    property Item coins_view: SelectCoinsView {
        account: stack_view.account
        property list<Action> actions: [
            Action {
                text: qsTrId('Done')
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
                enabled: controller.valid && !controller.transaction.error
                onTriggered: stack_view.push(review_view)
            }
        ]

        columns: 2
        rowSpacing: 12
        columnSpacing: 12

        SectionLabel {
            text: qsTrId('id_address')
        }

        RowLayout {
            GTextField {
                id: address_field
                selectByMouse: true
                Layout.fillWidth: true
                Layout.minimumWidth: contentWidth + 2 * padding
                font.pixelSize: 12
                onTextChanged: text = text.trim()
            }
            ToolButton {
                enabled: QtMultimedia.availableCameras.length > 0
                icon.source: 'qrc:/svg/qr.svg'
                icon.width: 16
                icon.height: 16
                onClicked: stack_view.push(scanner_view)
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
                }
                ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                ToolTip.text: qsTrId('id_paste')
                ToolTip.visible: hovered
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
            text: qsTrId('Coins')
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
                    { text: qsTrId('Manual coin selection'), enabled: true }
                ]
                bottomPadding: 13
                topPadding: 13
                contentItem: RowLayout {
                    spacing: 12
                    Image {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 24
                        source: icons[wallet.network.key]
                    }
                    Label {
                        text: wallet.network.name
                    }
                    Label {
                        Layout.fillWidth: true
                        text: {
                            if (coins_combo_box.currentIndex === 0) return qsTrId('(all coins)')
                            const count = send_view.selectedOutputs.length
                            if (count === 0) return qsTrId('(no coins selected)')
                            return qsTrId('(%1 coins selected)').arg(count)
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
                text: qsTrId('Send all')
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
                    text: wallet.network.liquid ? (balance.asset.data.name === 'btc' ? 'L-'+wallet.settings.unit : (balance.asset.data.ticker || '')) : wallet.settings.unit
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
                    text: wallet.settings.pricing.currency
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
    }
}
