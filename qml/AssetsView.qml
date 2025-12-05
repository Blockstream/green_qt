import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Pane {
    signal assetClicked(Asset asset)

    required property Context context
    readonly property var assets: {
        const context = self.context
        if (!context) return []
        const assets = new Map
        for (let i = 0; i < self.context.sessions.length; i++) {
            const session = self.context.sessions[i]
            const asset = context.getOrCreateAsset(session.network.policyAsset)
            assets.set(asset, { asset, satoshi: 0 })
        }
        for (let i = 0; i < context.accounts.length; i++) {
            const account = context.accounts[i]
            if (account.hidden) continue
            for (let asset_id in account.json.satoshi) {
                const satoshi = account.json.satoshi[asset_id]
                const asset = context.getOrCreateAsset(asset_id)
                let sum = assets.get(asset)
                if (sum) {
                    sum.satoshi += satoshi
                } else {
                    sum = { satoshi, asset }
                    assets.set(asset, sum)
                }
            }
        }
        return [...assets.values()].sort((a, b) => {
            if (a.asset.weight > b.asset.weight) return -1
            if (b.asset.weight > a.asset.weight) return 1
            if (b.asset.weight === 0) {
                if (a.asset.icon && !b.asset.icon) return -1
                if (!a.asset.icon && b.asset.icon) return 1
                if (Object.keys(a.asset.data).length > 0 && Object.keys(b.asset.data).length === 0) return -1
                if (Object.keys(a.asset.data).length === 0 && Object.keys(b.asset.data).length > 0) return 1
            }
            return a.asset.name.localeCompare(b.asset.name)
        })
    }
    id: self
    padding: 0
    background: null
    contentItem: ColumnLayout {
        spacing: 8
        ColumnLayout {
            spacing: 4
            visible: self.assets.length === 0
            Label {
                Layout.fillWidth: true
                color: '#929292'
                font.pixelSize: 14
                text: 'You don\'t have any assets yet.'
            }
            RowLayout {
                spacing: 0
                LinkButton {
                    text: 'Fund your wallet'
                }
                Label {
                    color: '#929292'
                    font.pixelSize: 14
                    font.weight: 400
                    text: ' now.'
                }
            }
        }
        Repeater {
            model: self.assets
            delegate: AssetButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.maximumHeight: 60
                Layout.minimumHeight: 60
                id: delegate
                asset: delegate.modelData.asset
                satoshi: delegate.modelData.satoshi
                onClicked: self.assetClicked(delegate.asset)
            }
        }
    }

    component AssetButton: AbstractButton {
        required property Asset asset
        required property var satoshi
        Convert {
            id: convert
            context: self.context
            asset: button.asset
            input: ({ satoshi: button.satoshi })
            unit: self.context.primarySession.unit
        }
        id: button
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        bottomPadding: 12
        background: Rectangle {
            border.color: '#262626'
            border.width: 1
            color: Qt.lighter('#181818', button.enabled && button.hovered ? 1.2 : 1)
            radius: 8
        }
        contentItem: RowLayout {
            spacing: 12
            AssetIcon {
                asset: button.asset
                size: 27
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: button.asset.name ? '#FFF' : '#929292'
                font.pixelSize: 16
                font.weight: 600
                text: button.asset.name || button.asset.id
                elide: Label.ElideRight
            }
            ColumnLayout {
                spacing: 0
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#00BCFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: UtilJS.incognito(Settings.incognito, convert.output.label)
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#A0A0A0'
                    font.pixelSize: 12
                    font.weight: 400
                    text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
                    visible: convert.fiat.available
                }
            }
            RightArrowIndicator {
                active: button.hovered
            }
        }
    }
}
