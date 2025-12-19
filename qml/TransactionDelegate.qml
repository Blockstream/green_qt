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

    contentItem: RowLayout {
        spacing: 10
        Image {
            Layout.alignment: Qt.AlignCenter
            source: `qrc:/svg2/tx-${transaction.data.type}.svg`
        }
        Label {
            Layout.fillWidth: true
            Layout.maximumWidth: 130
            color: '#FFF'
            font.pixelSize: 14
            font.weight: 600
            text: UtilJS.transactionTypeLabel(self.transaction)
        }
        Label {
            Layout.fillWidth: true
            Layout.maximumWidth: 130
            color: '#929292'
            text: UtilJS.formatTransactionTimestamp(self.transaction)
            font.pixelSize: 14
            font.weight: 400
            font.capitalization: Font.AllUppercase
            opacity: 0.6
        }
        AccountLabel {
            Layout.fillWidth: true
            Layout.maximumWidth: 150
            account: self.transaction.account
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
        // Repeater {
        //     id: assets_repeater
        //     model: self.transaction.amounts
        //     delegate: AssetIcon {
        //         asset: modelData.asset
        //     }
        // }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 150
            spacing: 1
            Repeater {
                model: Object.entries(self.transaction.data.satoshi)
                delegate: ColumnLayout {
                    required property var modelData
                    readonly property Asset asset: self.context.getOrCreateAsset(delegate.modelData[0])
                    readonly property var amount: delegate.modelData[1]
                    Convert {
                        id: convert
                        account: self.transaction.account
                        asset: delegate.asset
                        input: ({ satoshi: delegate.amount })
                        unit: self.transaction.account.session.unit
                    }
                    Layout.alignment: Qt.AlignRight
                    id: delegate
                    Label {
                        Layout.alignment: Qt.AlignRight
                        color: delegate.amount > 0 ? '#00BCFF' : '#FFFFFF'
                        font.pixelSize: 14
                        font.weight: 600
                        text: UtilJS.incognito(Settings.incognito, convert.output.label)
                    }
                    Label {
                        Layout.alignment: Qt.AlignRight
                        color: '#929292'
                        font.pixelSize: 12
                        font.weight: 400
                        text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
                        visible: convert.fiat.available
                    }
                    visible: {
                        if (delegate.amount === 0) return false
                        if (!self.transaction.account.network.liquid) return true
                        if (delegate.asset.id !== self.transaction.account.network.policyAsset) return true
                        if (self.transaction.data.type === 'redeposit') return true
                        return (delegate.amount + self.transaction.data.fee) !== 0
                    }
                }
            }
        }
    }
}
