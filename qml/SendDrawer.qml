import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Account account
    property Asset asset

    SendController {
        id: controller
        context: self.account.context
        account: self.account
        asset: self.asset
        balance: asset_field_loader.item?.balance ?? null
        address: address_field.text
        sendAll: send_all_button.checked
        manualCoinSelection: coins_combo_box.currentIndex === 1
        utxos: {
            var r = {}
            for (const u of coins_view.selectedOutputs) {
                const policy = u.asset ? u.asset.id : 'btc'
                if (policy in r) {
                    r[policy].push(u.data)
                } else {
                    r[policy] = [u.data]
                }
            }
            return r
        }
        onFinished: {
            Analytics.recordEvent('send_transaction', AnalyticsJS.segmentationTransaction(self.account, {
                address_input: self.address_input,
                transaction_type: 'send',
                with_memo: controller.memo !== '',
            }))
        }
// TODO send controller should emit error signal if sign or send tasks fails
//        onError: {
//            Analytics.recordEvent('failed_transaction', AnalyticsJS.segmentationSession(self.account.context.wallet))
//        }
    }

    id: self
    width: 500
    contentItem: GStackView {
        id: stack_view
        initialItem: Form {
        }
    }

    component FieldTitle: Label {
        font.family: 'SF Compact Display'
        font.pixelSize: 14
        font.weight: 600
        opacity: 0.4
    }

    component Form: Page {
        background: null
        header: Pane {
            background: null
            padding: 0
            bottomPadding: 20
            contentItem: RowLayout {
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 20
                    font.weight: 790
                    text: qsTrId('id_send')
                }
                HSpacer {
                }
                CloseButton {
                    onClicked: self.close()
                }
            }
        }
        contentItem: ColumnLayout {
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
                onClicked: stack_view.push(account_asset_selector)
            }
            FieldTitle {
                text: 'Enter Address'
            }
            ScannerPopup {
                id: scanner_popup
                parent: address_field
                onCodeScanned: {
                    parsePayment(code)
                    self.address_input = 'scan'
                }
            }
            AddressField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                id: address_field
                focus: true
            }
            FieldTitle {
                text: qsTrId('Amount')
            }
            AmountField {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                text: controller.amount
            }
            Loader {
                id: ledger_support_warning
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                active: {
                    // TODO
                    return false
                    const device = account.context.device
                    const asset = asset_field_loader.item?.balance?.asset
                    if (device?.type === Device.LedgerNanoS && device.appVersion === '1.4.8' && asset) {
                        switch (asset.id) {
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
//            Loader {
//                id: asset_field_loader
//                visible: active
//                active: account.network.liquid
//                Layout.fillWidth: true
//                sourceComponent: GComboBox {
//                    property Balance balance: account.balances[asset_field.currentIndex]
//                    property Asset asset: balance.asset
//                    id: asset_field

//                    model: account.balances
//                    delegate: AssetDelegate {
//                        highlighted: index === asset_field.currentIndex
//                        balance: modelData
//                        width: parent.width
//                    }

//                    leftPadding: 8
//                    topPadding: 12
//                    bottomPadding: 12

//                    contentItem: BalanceItem {
//                        balance: account.balances[asset_field.currentIndex]
//                    }
//                }
//            }
//            SectionLabel {
//                text: qsTrId('id_coins')
//                visible: !account.network.liquid
//            }
//            RowLayout {
//                spacing: 16
//                visible: !account.network.liquid
//                GComboBox {
//                    Layout.fillWidth: true
//                    id: coins_combo_box
//                    model: [
//                        { text: qsTrId('Use all available coins'), enabled: true },
//                        { text: qsTrId('id_manual_coin_selection'), enabled: true }
//                    ]
//                    bottomPadding: 13
//                    topPadding: 13
//                    contentItem: RowLayout {
//                        spacing: 12
//                        Image {
//                            Layout.preferredHeight: 24
//                            Layout.preferredWidth: 24
//                            source: UtilJS.iconFor(wallet)
//                        }
//                        Label {
//                            text: account.network.displayName
//                        }
//                        Label {
//                            Layout.fillWidth: true
//                            text: {
//                                if (coins_combo_box.currentIndex === 0) return qsTrId('id_all_coins')
//                                const count = coins_view.selectedOutputs.length
//                                if (count === 0) return qsTrId('id_no_coins_selected')
//                                return qsTrId('id_d_coins_selected').arg(count)
//                            }
//                        }
//                        Label {
//                            text: {
//                                const balance = asset_field_loader.item?.balance
//                                const asset = balance?.asset

//                                if (coins_combo_box.currentIndex === 0) {
//                                    return balance ? balance.displayAmount : formatAmount(account, account.balance)
//                                }

//                                var x = 0
//                                for (const u of coins_view.selectedOutputs) {
//                                    if (!u.asset || u.asset === asset) {
//                                        x += u.data['satoshi']
//                                    }
//                                }
//                                return asset ? asset.formatAmount(x, true) : formatAmount(self.account, x)
//                            }
//                        }
//                    }
//                    delegate: ItemDelegate {
//                        width: coins_combo_box.width
//                        text: modelData.text
//                        highlighted: ListView.isCurrentItem
//                        enabled: modelData.enabled
//                    }
//                }
//                GButton {
//                    large: true
//                    visible: coins_combo_box.currentIndex === 1
//                    onClicked: coins_view.active = true
//                    text: 'Select Coins'
//                }
//            }
//            SectionLabel {
//                text: qsTrId('id_amount')
//            }
//            RowLayout {
//                spacing: 12
//                GSwitch {
//                    Layout.fillWidth: true
//                    id: send_all_button
//                    text: qsTrId('id_send_all')
//                }
//                GTextField {
//                    id: amount_field
//                    Layout.fillWidth: true
//                    enabled: !send_all_button.checked
//                    horizontalAlignment: TextField.AlignRight
//                    selectByMouse: true

//                    placeholderText: controller.effectiveAmount
//                    text: controller.amount
//                    onTextChanged: {
//                        if (!activeFocus) return;
//                        controller.amount = text;
//                    }
//                    validator: AmountValidator {
//                    }
//                    Label {
//                        id: unit
//                        anchors.right: parent.right
//                        anchors.rightMargin: 8
//                        anchors.baseline: parent.baseline
//                        text: {
//                            const network = account.network
//                            if (network.liquid && balance && balance.asset.id !== network.policyAsset) {
//                                return balance.asset.data.ticker || ''
//                            }
//                            return account.session.displayUnit
//                        }
//                    }
//                    rightPadding: unit.width + 16
//                }

//                Label {
//                    enabled: controller.hasFiatRate
//                    text: '≈'
//                }

//                GTextField {
//                    id: fiat_field
//                    Layout.fillWidth: true
//                    enabled: !send_all_button.checked && controller.hasFiatRate && fiatRateAvailable
//                    horizontalAlignment: TextField.AlignRight
//                    placeholderText: controller.effectiveFiatAmount
//                    text: controller.fiatAmount
//                    selectByMouse: true
//                    onTextChanged: {
//                        if (!activeFocus) return;
//                        controller.fiatAmount = text
//                    }
//                    validator: AmountValidator {
//                    }
//                    Label {
//                        id: currency
//                        anchors.right: parent.right
//                        anchors.rightMargin: 8
//                        anchors.baseline: parent.baseline
//                        text: account.network.mainnet ? self.session.settings.pricing.currency : 'FIAT'
//                    }
//                    rightPadding: currency.width + 16
//                }
//            }
            VSpacer {
            }
            RowLayout {
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 500
                    text: qsTrId('id_network_fee')
                }
                HSpacer {
                }
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 500
                    text: '0,000012 L-BTC'
                }
            }
            RowLayout {
                Layout.bottomMargin: 20
                Label {
                    color: '#6F6F6F'
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~2 hours'
                }
                LinkButton {
                    text: 'Change speed'
                }
                HSpacer {
                }
                Label {
                    color: '#6F6F6F'
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~2,23 USD'
                }
            }
            RowLayout {
                Layout.bottomMargin: 65
                spacing: 20
                RegularButton {
                    Layout.fillWidth: true
                    implicitWidth: 0
                    text: 'Advanced Options'
                }
                PrimaryButton {
                    Layout.fillWidth: true
                    implicitWidth: 0
                    text: qsTrId('id_next')
                }
            }

/*
            RowLayout {
                spacing: 12
                FeeComboBox {
                    account: self.account
                    id: fee_combo
                    Layout.fillWidth: true
                    property var indexes: [3, 12, 24]
                    extra: account.network.liquid ? [] : [{ text: qsTrId('id_custom') }]
                    Component.onCompleted: {
                        currentIndex = self.account.network.liquid ? 0 : indexes.indexOf(self.session.settings.required_num_blocks)
                        console.log(currentIndex, blocks, fee_combo.fees)
                        controller.feeRate = fee_combo.fees[blocks]
                    }
                    onFeeRateChanged: {
                        if (feeRate) {
                            controller.feeRate = feeRate
                        }
                    }
                    onCurrentIndexChanged: {
                        if (currentIndex === 3) {
                            custom_fee_field.clear()
                            custom_fee_field.forceActiveFocus()
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
            }
            RowLayout {
                Layout.fillHeight: false
                HSpacer {
                }
                GButton {
                    highlighted: enabled
                    text: controller.transaction.error ? qsTrId(controller.transaction.error || '') : qsTrId('id_review')
                    enabled: !ledger_support_warning.active && controller.valid && !controller.transaction.error
                    onClicked: self.review = true
                }
            }
            */
        }
    }
    /*
    SelectCoinsView {
        id: coins_view
        property bool active: false
        account: self.account
        visible: active
        footer: RowLayout {
            HSpacer {
            }
            GButton {
                text: qsTrId('id_done')
                onClicked: coins_view.active = false
            }
        }
    }

    AnimLoader {
        animated: true
        active: controller.signedTransaction
        sourceComponent: ColumnLayout {
            spacing: constants.p1
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: 'qrc:/svg/check.svg'
                sourceSize.width: 64
                sourceSize.height: 64
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTrId('id_transaction_sent')
                font.pixelSize: 20
            }
            CopyableLabel {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: constants.p1
                font.pixelSize: 12
                delay: 50
                text: controller.signedTransaction.data.txhash
                onCopy: Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(self.account))
            }
            VSpacer {
            }
        }
    }

    /*
    AnimLoader {
        animated: true
        active: self.review
        sourceComponent: ColumnLayout {
            spacing: constants.s1
            AnalyticsView {
                name: 'SendConfirm'
                active: true
                segmentation: AnalyticsJS.segmentationSubAccount(controller.account)
            }
            AlertView {
                alert: AnalyticsAlert {
                    screen: 'SendConfirm'
                    network: controller.account.network.id
                }
            }
            SectionLabel {
                text: qsTrId('id_fee')
            }
            Label {
                text: formatAmount(self.account, controller.transaction.fee) + ' ≈ ' + formatFiat(controller.transaction.fee)
            }
            Repeater {
                model: controller.transaction.transaction_outputs.filter(output => !output.is_change && output.script.length > 0)
                delegate: controller.account.network.liquid ? liquid_output: bitcoin_output
            }
            SectionLabel {
                text: qsTrId('id_my_notes')
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.maximumHeight: 128
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.interactive: hovered
                GTextArea {
                    id: memo_edit
                    Layout.fillWidth: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    text: controller.memo
                    onTextChanged: {
                        if (text.length > 1024) {
                            text = text.slice(0, 1024);
                        }
                        controller.memo = memo_edit.text;
                    }
                }
            }
            VSpacer {
            }
            RowLayout {
                Layout.fillHeight: false
                HSpacer {
                }
                GButton {
                    text: qsTrId('id_back')
                    onClicked: self.review = false
                }
                GButton {
                    text: qsTrId('id_send')
                    onClicked: controller.signAndSend()
                }
            }
            Component {
                id: bitcoin_output
                ColumnLayout {
                    spacing: constants.s1
                    SectionLabel {
                        text: qsTrId('id_address')
                    }
                    Label {
                        text: modelData.address
                    }
                    SectionLabel {
                        text: qsTrId('id_amount')
                    }
                    Label {
                        text: formatAmount(self.account, modelData.satoshi) + ' ≈ ' + formatFiat(modelData.satoshi)
                    }
                }
            }
            Component {
                id: liquid_output
                ColumnLayout {
                    property Asset address_asset: self.account.context.getOrCreateAsset(modelData.asset_id)
                    spacing: constants.s1
                    SectionLabel {
                        text: qsTrId('id_address')
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        text: modelData.address
                        wrapMode: Text.WrapAnywhere
                    }
                    SectionLabel {
                        text: qsTrId('id_asset')
                    }
                    RowLayout {
                        spacing: 8
                        AssetIcon {
                            asset: address_asset
                        }
                        Label {
                            text: address_asset.name
                            elide: Label.ElideMiddle
                        }
                    }
                    SectionLabel {
                        text: qsTrId('id_amount')
                    }
                    Label {
                        text: {
                            self.session.displayUnit
                            return address_asset.formatAmount(modelData.satoshi, true, self.session.unit)
                        }
                    }
                }
            }
        }
    }
    */

    AnalyticsView {
        name: 'Send'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSubAccount(self.account)
    }

    Component {
        id: account_asset_selector
        AccountAssetSelector {
            account: controller.account
            asset: controller.asset
            onCanceled: stack_view.pop()
            onSelected: (account, asset) => {
                stack_view.pop()
                controller.account = account
                controller.asset = asset
            }
        }
    }
}
