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
    required property Context context
    required property Transaction transaction
    property Account account: transaction.account

    property var tx: transaction.data
    property int confirmations: transactionConfirmations(transaction)

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
            color: '#00BCFF'
            opacity: 0.08
        }
        Rectangle {
            color: '#1F222A'
            width: parent.width
            height: 1
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
        if (transaction.type === Transaction.Incoming) {
            if (tx.outputs.length > 0) {
                for (const o of tx.outputs) {
                    if (o.is_relevant) {
                        return qsTrId('id_received')
                    }
                }
            } else {
                return qsTrId('id_received')
            }
        }
        if (transaction.type === Transaction.Outgoing) {
            return qsTrId('id_sent')
        }
        if (transaction.type === Transaction.Redeposit) {
            return qsTrId('id_redeposited')
        }
        if (transaction.type === Transaction.Mixed) {
            return qsTrId('id_swap')
        }
        if (transaction.type === Transaction.NotUnblindable) {
            return 'Not unblindable'
        }
        return JSON.stringify(tx, null, '\t')
    }
    contentItem: RowLayout {
        spacing: 20
        Image {
            Layout.alignment: Qt.AlignCenter
            source: `qrc:/svg2/tx-${transaction.data.type}.svg`
        }
        Label {
            Layout.minimumWidth: self.width / 5
            color: '#FFF'
            font.pixelSize: 14
            font.weight: 600
            text: txType(tx)
        }
        Label {
            Layout.minimumWidth: self.width / 5
            color: '#929292'
            text: UtilJS.formatTransactionTimestamp(tx)
            font.pixelSize: 12
            font.weight: 400
            font.capitalization: Font.AllUppercase
            opacity: 0.6
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 0
            Layout.fillWidth: true
            color: '#929292'
            font.pixelSize: 12
            font.weight: 400
            text: {
                const lines = transaction.memo.trim().split('\n')
                return lines[0] + (lines.length > 1 ? '...' : '')
            }
            wrapMode: Label.Wrap
        }
        TransactionStatusBadge {
            transaction: self.transaction
            confirmations: self.confirmations
        }
        Repeater {
            id: assets_repeater
            model: self.transaction.amounts
            delegate: AssetIcon {
                asset: modelData.asset
            }
        }
        Label {
            Layout.alignment: Qt.AlignRight
            color: '#929292'
            font.pixelSize: 12
            font.weight: 400
            text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
            visible: Number(convert.result.satoshi ?? '0') !== 0
        }
        ColumnLayout {
            Layout.fillWidth: false
            Layout.minimumWidth: self.width / 5
            spacing: 1
            Repeater {
                model: self.transaction.amounts
                delegate: Label {
                    Convert {
                        id: convert
                        account: self.account
                        asset: modelData.asset
                        input: ({ satoshi: modelData.amount })
                    }
                    Layout.alignment: Qt.AlignRight
                    color: transaction.data.type === 'incoming' ? '#00BCFF' : '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: UtilJS.incognito(Settings.incognito, convert.output.label)
                }
            }

            Convert {
                id: convert
                account: self.account
                input: {
                    const network = transaction.account.network
                    const satoshi = transaction.data.satoshi
                    return { satoshi: String((satoshi[network.policyAsset] ?? 0) - transaction.data.fee) }
                }
                unit: self.account.session.unit
            }
            /*
            Label {
                Layout.alignment: Qt.AlignRight
                color: transaction.data.type === 'incoming' ? '#00BCFF' : '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: UtilJS.incognito(Settings.incognito, convert.output.label)
                visible: Number(convert.result.satoshi ?? '0') !== 0
            }*/
        }
    }
}
