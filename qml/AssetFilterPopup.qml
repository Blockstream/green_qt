import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

FilterPopup {
    required property Context context
    required property ContextModel model
    property var filterAssets
    property var assets
    Component.onCompleted: {
        self.filterAssets = [...self.model.filterAssets]
        const context = self.context
        if (!context) return []
        const assets = new Map
        for (let i = 0; i < context.accounts.length; i++) {
            const account = context.accounts[i]
            for (let asset_id in account.json.satoshi) {
                const satoshi = account.json.satoshi[asset_id]
                if (satoshi === 0) continue
                const asset = context.getOrCreateAsset(asset_id)
                if (self.filterAssets.indexOf(asset) >= 0) continue
                let sum = assets.get(asset)
                if (sum) {
                    sum.satoshi += satoshi
                } else {
                    sum = { satoshi, asset }
                    assets.set(asset, sum)
                }
            }
        }
        self.assets = [...assets.values()].sort((a, b) => {
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
    Repeater {
        model: self.filterAssets
        delegate: Delegate {
            required property var modelData
            Layout.fillWidth: true
            Layout.maximumWidth: 400
            id: delegate2
            asset: delegate2.modelData
        }
    }
    FilterPopup.Separator {
        visible: self.filterAssets.length > 0 && self.assets.length > 0
    }
    Repeater {
        model: self.assets
        delegate: Delegate {
            required property var modelData
            Layout.fillWidth: true
            Layout.maximumWidth: 400
            id: delegate
            asset: delegate.modelData.asset
        }
    }
    component Delegate: AbstractButton {
        required property Asset asset
        checkable: true
        checked: self.model.filterAssets.indexOf(button.asset) >= 0
        onClicked: {
            self.model.updateFilterAssets(button.asset, self.model.filterAssets.indexOf(button.asset) < 0)
        }
        id: button
        leftPadding: 12
        rightPadding: 12
        topPadding: 4
        bottomPadding: 4
        background: Rectangle {
            color: '#FFF'
            radius: 8
            opacity: 0.2
            visible: button.hovered
        }
        contentItem: RowLayout {
            spacing: 12
            AssetIcon {
                asset: button.asset
                size: 24
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                color: button.asset.name ? '#FFF' : '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: button.asset.name || button.asset.id
                elide: Label.ElideMiddle
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/check.svg'
                opacity: button.checked ? 1 : 0
            }
        }
    }
}
