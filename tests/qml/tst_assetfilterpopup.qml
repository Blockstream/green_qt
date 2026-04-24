import QtQuick
import QtTest
import Blockstream.Green

GreenTestCase {
    name: "tst_assetfilterpopup"

    function test_aggregatesAndSortsAssets() {
        const btc = Qt.createQmlObject('import Blockstream.Green 1.0; Asset { id: "btc"; name: "Bitcoin"; weight: 10; icon: "qrc:/svg/btc.svg" }', this)
        const usdt = Qt.createQmlObject('import Blockstream.Green 1.0; Asset { id: "usdt"; name: "Tether"; weight: 1; data: ({ ticker: "USDT" }) }', this)

        const account1 = { hidden: false, json: ({ satoshi: ({ btc: 100, usdt: 0 }) }), network: ({ electrum: false, liquid: false }) }
        const account2 = { hidden: false, json: ({ satoshi: ({ usdt: 500 }) }), network: ({ electrum: false, liquid: false }) }

        const context = Qt.createQmlObject('import Blockstream.Green 1.0; Context {}', this)
        context.registerAsset(btc)
        context.registerAsset(usdt)
        context.accounts = [account1, account2]

        const model = Qt.createQmlObject('import Blockstream.Green 1.0; ContextModel {}', this)
        model.filterAssets = []

        const popupComponent = Qt.createComponent("../../qml/AssetFilterPopup.qml")
        verify(popupComponent.status === Component.Ready, popupComponent.errorString())
        const popup = popupComponent.createObject(this, { context: context, model: model })
        verify(popup !== null)

        compare(popup.assets.length, 2)
        compare(popup.assets[0].asset.id, "btc")
        compare(popup.assets[0].satoshi, 100)
        compare(popup.assets[1].asset.id, "usdt")
        compare(popup.assets[1].satoshi, 500)

        popup.destroy()
        model.destroy()
        context.destroy()
        btc.destroy()
        usdt.destroy()
    }
}
