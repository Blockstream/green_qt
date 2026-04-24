import QtQuick
import Blockstream.Green

QtObject {
    property var accounts: []
    property var sessions: []
    property bool lightningEnabled: false
    property var lightningNodeInfo: ({})
    property var _assets: ({})
    property var primarySession: ({
        unit: "btc",
        settings: { pricing: { currency: "USD" } }
    })

    function registerAsset(asset) {
        _assets[asset.id] = asset
    }

    function getOrCreateAsset(assetId) {
        return _assets[assetId]
    }
}
