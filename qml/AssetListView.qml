import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    signal assetClicked(Asset asset)
    required property Context context
    required property Account account
    id: self
    background: Rectangle {
        color: '#161921'
        border.width: 1
        border.color: '#1F222A'
        radius: 4
    }
    contentItem: TListView {
        id: list_view
        model: {
            const deployment = self.context.deployment
            const entries = Object.entries(self.account.json.satoshi)
            const assets = entries.map(([id, satoshi]) => ({ asset: AssetManager.assetWithId(deployment, id), satoshi }))
            return assets.sort((a, b) => {
                if (a.asset.data.name === 'btc') return -1
                if (b.asset.data.name === 'btc') return 1
                if (a.asset.icon && !b.asset.icon) return -1
                if (!a.asset.icon && b.asset.icon) return 1
                return a.asset.id.localeCompare(b.asset.id)
            })
        }
        spacing: 0
        delegate: AssetDelegate {
            account: self.account
            asset: modelData.asset
            satoshi: modelData.satoshi
            onAssetClicked: (asset) => self.assetClicked(asset)
        }
    }
}
