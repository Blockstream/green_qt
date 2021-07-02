import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtMultimedia 5.13
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

StackView {
    id: stack_view
    property alias address: address_field.text
    property Balance balance: asset_field_loader.item ? asset_field_loader.item.balance : null
    property alias sendAll: send_all_button.checked

    property var actions: currentItem.actions

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

    implicitHeight: currentItem.implicitHeight
    implicitWidth: currentItem.implicitWidth

    Component {
        id: review_view
        ReviewView {}
    }

    initialItem: ColumnLayout {
        id: setup_view
        property list<Action> actions: [
            Action {
                text: controller.transaction.error ? qsTrId(controller.transaction.error || '') : qsTrId('id_review')
                enabled: controller.valid && !controller.transaction.error
                onTriggered: stack_view.push(review_view)
            }
        ]

        spacing: 0

        SectionLabel { text: qsTrId('id_address') }

        RowLayout {
            GTextField {
                id: address_field
                selectByMouse: true
                Layout.fillWidth: true
                horizontalAlignment: TextField.AlignHCenter
                placeholderText: qsTrId('id_enter_an_address')
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
                icon.width: 16
                icon.height: 16
                onClicked: {
                    address_field.clear();
                    address_field.paste();
                }
                ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                ToolTip.text: qsTrId('id_paste')
                ToolTip.visible: hovered
            }
        }
        SectionLabel { text: qsTrId('id_asset'); visible: wallet.network.liquid }
        Loader {
            id: asset_field_loader
            active: wallet.network.liquid
            Layout.fillWidth: true
            sourceComponent: ComboBox {
                property Balance balance: account.balances[asset_field.currentIndex]
                property Asset asset: balance.asset
                id: asset_field
                flat: true
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
        SectionLabel { text: qsTrId('id_amount') }
        RowLayout {
            spacing: 16
            Switch {
                id: send_all_button
                text: qsTrId('id_send_all_funds')
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
        SectionLabel { text: qsTrId('id_network_fee') }
        RowLayout {
            FeeComboBox {
                id: fee_combo
                Layout.fillWidth: true
                property var indexes: [3, 12, 24]
                extra: wallet.network.liquid ? [] : [{ text: qsTrId('id_custom') }]
                Component.onCompleted: {
                    currentIndex = wallet.network.liquid ? 0 : indexes.indexOf(wallet.settings.required_num_blocks)
                    controller.feeRate = wallet.events.fees[blocks]
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
