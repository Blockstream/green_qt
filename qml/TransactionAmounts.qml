import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

ColumnLayout {
    required property Context context
    required property Transaction transaction
    id: self
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
                unit: UtilJS.unit(self.context)
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
