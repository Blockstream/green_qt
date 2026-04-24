import QtQuick
import QtTest
import Blockstream.Green
import Blockstream.Green.Core

GreenTestCase {
    name: "tst_transactionamounts"

    function test_delegateVisibilityRules_data() {
        return [
            { tag: "zero amount hidden, other asset shown", liquid: true, satoshi: { btc: 0, usdt: 25 }, fee: 10, type: "incoming", expected: { btc: false, usdt: true } },
            { tag: "bitcoin amount shown even if it equals fee", liquid: false, satoshi: { btc: -10 }, fee: 10, type: "outgoing", expected: { btc: true } },
            { tag: "liquid policy asset paying only fee hidden", liquid: true, satoshi: { btc: -10, usdt: -25 }, fee: 10, type: "outgoing", expected: { btc: false, usdt: true } },
            { tag: "liquid policy asset with amount shown", liquid: true, satoshi: { btc: -110 }, fee: 10, type: "outgoing", expected: { btc: true } },
            { tag: "liquid redeposit shown", liquid: true, satoshi: { btc: -10 }, fee: 10, type: "redeposit", expected: { btc: true } },
            { tag: "lightning shown", lightning: true, satoshi: { btc: 5 }, fee: -5, type: "incoming", expected: { btc: true } }
        ]
    }

    function test_delegateVisibilityRules(row) {
        const btc = Qt.createQmlObject('import Blockstream.Green 1.0; Asset { id: "btc"; name: "Bitcoin" }', this)
        const usdt = Qt.createQmlObject('import Blockstream.Green 1.0; Asset { id: "usdt"; name: "Tether" }', this)

        const context = Qt.createQmlObject('import Blockstream.Green 1.0; Context {}', this)
        context.registerAsset(btc)
        context.registerAsset(usdt)

        const tx = row.lightning
            ? Qt.createQmlObject('import Blockstream.Green.Core 1.0; LightningTransaction {}', this)
            : Qt.createQmlObject('import Blockstream.Green.Core 1.0; AccountTransaction {}', this)
        if (!row.lightning) tx.account = { network: { liquid: row.liquid, policyAsset: "btc" } }
        tx.data = { satoshi: row.satoshi, type: row.type, fee: row.fee }

        const component = Qt.createComponent("../../qml/TransactionAmounts.qml")
        verify(component.status === Component.Ready, component.errorString())
        const view = component.createObject(this, { context: context, transaction: tx })
        verify(view !== null)

        const delegates = findItems(view, item => item.amount !== undefined)
        compare(delegates.length, Object.keys(row.expected).length)
        for (const delegate of delegates) {
            compare(delegate.visible, row.expected[delegate.asset.id], `${delegate.asset.id} visible`)
        }

        view.destroy()
        tx.destroy()
        context.destroy()
        btc.destroy()
        usdt.destroy()
    }
}
