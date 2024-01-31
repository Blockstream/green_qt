import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    readonly property var assets: {
        const context = self.context
        const assets = new Set
        if (context) {
            for (let i = 0; i < context.accounts.length; i++) {
                const account = context.accounts[i]
                if (!account.json.satoshi) continue
                for (const [asset_id, satoshi] of Object.entries(account.json.satoshi)) {
                    if (satoshi === 0) continue
                    const asset = context.getOrCreateAsset(asset_id)
                    if (!asset.icon && asset.weight === 0) continue
                    assets.add(asset)
                }
            }
        }
        return [...assets].sort((a, b) => {
            if (a.weight > b.weight) return -1
            if (b.weight > a.weight) return 1
            if (b.weight === 0) {
                if (a.icon && !b.icon) return -1
                if (!a.icon && b.icon) return 1
                if (Object.keys(a.data).length > 0 && Object.keys(b.data).length === 0) return -1
                if (Object.keys(a.data).length === 0 && Object.keys(b.data).length > 0) return 1
            }
            return a.name.localeCompare(b.name)
        }).reverse()
    }
    readonly property bool withoutIcon: {
        const context = self.context
        if (context) {
            for (let i = 0; i < context.accounts.length; i++) {
                const account = context.accounts[i]
                for (const [asset_id, satoshi] of Object.entries(account.json?.satoshi ?? [])) {
                    if (satoshi === 0) continue
                    const asset = context.getOrCreateAsset(asset_id)
                    if (!asset.icon && asset.weight === 0) return true
                }
            }
        }
        return false
    }
    id: self
    visible: self.assets.length > 0
    headerItem: RowLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            opacity: 0.6
            source: 'qrc:/svg2/star.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.capitalization: Font.AllUppercase
            font.pixelSize: 12
            font.weight: 400
            opacity: 0.6
            text: qsTrId('id_assets')
        }
        HSpacer {
            Layout.minimumHeight: 28
        }
    }
    contentItem: ColumnLayout {
        RowLayout {
            Layout.fillHeight: false
            spacing: -12
            AssetIcon {
                visible: self.withoutIcon
            }
            Repeater {
                model: self.assets
                AssetIcon {
                    asset: modelData
                }
            }
        }
        VSpacer {
        }
    }
}
