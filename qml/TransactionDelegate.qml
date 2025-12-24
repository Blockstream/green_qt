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
            elide: Label.ElideRight
            color: '#929292'
            font.pixelSize: 12
            font.weight: 400
            text: {
                const lines = transaction.memo.trim().split('\n')
                return lines[0] + (lines.length > 1 ? '...' : '')
            }
            wrapMode: Label.NoWrap
        }
        TransactionStatusBadge {
            confirmations: self.confirmations
            liquid: self.transaction.account.network.liquid
        }
        TransactionAmounts {
            Layout.fillWidth: true
            Layout.maximumWidth: 150
            context: self.context
            transaction: self.transaction
        }
    }
}
