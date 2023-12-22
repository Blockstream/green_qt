import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ItemDelegate {
    signal transactionClicked(Transaction transaction)
    required property Transaction transaction
    required property Account account
    required property Context context

    property var tx: transaction.data
    property int confirmations: transactionConfirmations(transaction)
    readonly property var spv: {
        const liquid = transaction.account.network.liquid
        const unconfirmed = (liquid && confirmations < 2) || (!liquid && confirmations < 6)
        if (unconfirmed) return null
        switch (transaction.spv) {
        case Transaction.Disabled:
        case Transaction.Unconfirmed:
        case Transaction.Verified:
            return null
        case Transaction.NotVerified:
            return { icon: 'qrc:/svg/tx-spv-not-verified.svg', text: qsTrId('id_invalid_merkle_proof') }
        case Transaction.NotLongest:
            return { icon: 'qrc:/svg/tx-spv-not-longest.svg', text: qsTrId('id_not_on_longest_chain') }
        case Transaction.InProgress:
            return { icon: 'qrc:/svg/tx-spv-in-progress.svg', text: qsTrId('id_verifying_transactions') }
        }
    }

    onClicked: self.transactionClicked(transaction)

    id: self
    focusPolicy: Qt.ClickFocus
    leftPadding: 20
    rightPadding: 20
    topPadding: 20
    bottomPadding: 20
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00B45A'
            opacity: 0.08
        }
        Rectangle {
            color: '#1F222A'
            width: parent.width
            height: 1
            y: parent.height - 1
        }
    }
    spacing: 0

    function txType(tx) {
        // const memo = transaction.memo.trim().replace(/\n/g, ' ')
        // const separator = memo === '' ? '' : ' - '
        if (transaction.type === Transaction.Incoming) {
            if (tx.outputs.length > 0) {
                for (const o of tx.outputs) {
                    if (o.is_relevant) {
                        return qsTrId('id_received')// + separator + memo
                    }
                }
            } else {
                return qsTrId('id_received')// + separator + memo
            }
        }
        if (transaction.type === Transaction.Outgoing) {
            return qsTrId('id_sent')// + separator + memo
        }
        if (transaction.type === Transaction.Redeposit) {
            return qsTrId('id_redeposited')// + separator + memo
        }
        if (transaction.type === Transaction.Mixed) {
            return qsTrId('id_swap')// + separator + memo
        }
        return JSON.stringify(tx, null, '\t')
    }
    Action {
        id: copy_unblinding_data_action
        text: qsTrId('id_copy_unblinding_data')
        onTriggered: copyUnblindingData(tool_button, tx)
    }
    contentItem: RowLayout {
        spacing: 20
        Image {
            Layout.alignment: Qt.AlignCenter
            source: `qrc:/svg2/tx-${transaction.data.type}.svg`
        }
        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignCenter
            spacing: 1
            Label {
                color: '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: txType(tx)
            }
            Label {
                color: '#929292'
                text: UtilJS.formatTransactionTimestamp(tx)
                font.pixelSize: 12
                font.weight: 400
                font.capitalization: Font.AllUppercase
                opacity: 0.6
            }
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 0
            Layout.fillWidth: true
            color: '#929292'
            font.pixelSize: 12
            font.weight: 400
            text: transaction.memo
            wrapMode: Label.Wrap
        }
        TransactionStatusBadge {
            transaction: self.transaction
            confirmations: self.confirmations
            visible: confirmations < (transaction.account.network.liquid ? 1 : 6)
        }
        Loader {
            active: spv
            visible: active
            sourceComponent: Image {
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                source: spv.icon
                sourceSize.height: 24
            }
        }
        Repeater {
            model: {
                const assets = []
                if (self.account.network.liquid) {
                    for (const [id, satoshi] of Object.entries(transaction.data.satoshi)) {
                        if (self.account.network.policyAsset === id) continue
                        const asset = AssetManager.assetWithId(self.account.context.deployment, id)
                        if (asset && asset.icon) assets.push(asset)
                    }
                }
                return assets
            }
            delegate: AssetIcon {
                asset: modelData
            }
        }

        ColumnLayout {
            Layout.fillWidth: false
            Layout.minimumWidth: 150
            spacing: 1
            Repeater {
                model: {
                    const assets = []
                    if (self.account.network.liquid) {
                        for (const [id, satoshi] of Object.entries(transaction.data.satoshi)) {
                            if (self.account.network.policyAsset === id) continue
                            const asset = AssetManager.assetWithId(self.account.context.deployment, id)
                            const ticker = asset.data.ticker
                            if (ticker) {
                                assets.push('' + satoshi + ' ' + ticker)
                            } else {
                                assets.push('' + satoshi)
                            }
                        }
                    }
                    return assets
                }
                delegate: Label {
                    Layout.alignment: Qt.AlignRight
                    color: transaction.data.type === 'incoming' ? '#00B670' : '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: modelData
                }
            }
            Convert {
                id: convert
                account: self.account
                unit: 'sats'
                value: transaction.account.network.liquid ? transaction.data.satoshi[transaction.account.network.policyAsset] : transaction.data.satoshi.btc
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: transaction.data.type === 'incoming' ? '#00B670' : '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: convert.unitLabel
                visible: convert.value < 0 || convert.value > 0
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: convert.fiatLabel
                visible: convert.value < 0 || convert.value > 0
            }

//            Repeater {
//                model: Object.entries(transaction.data.satoshi)
//                delegate: Label {
//                    text: JSON.stringify(modelData, null, '  ')
//                    visible: {
//                        const network = transaction.account.network
//                        const [id, amount] = modelData
//                        if (network.liquid && transaction.type === Transaction.Outgoing && id === network.policyAsset && amount === -transaction.data.fee) return false
//                        return true
//                    }
//                    Layout.alignment: Qt.AlignRight
//                    color: modelData[1] > 0 ? '#00b45a' : 'white'
//                    font.pixelSize: 14
//                    font.styleName: 'Medium'
//                    text: {
//                        const account = self.transaction.account
//                        const network = account.network
//                        const [id, amount] = modelData
//                        if (network.liquid) {
//                            return UtilJS.incognitoAmount(self.account, self.context.getOrCreateAsset(id).formatAmount(amount, true))
//                        } else {
//                            return UtilJS.incognitoAmount(self.account, formatAmount(account, amount))
//                        }
//                    }
//                }
//            }
        }
    }
}
