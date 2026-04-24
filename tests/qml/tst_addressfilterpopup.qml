import QtQuick
import QtTest
import Blockstream.Green

GreenTestCase {
    name: "tst_addressfilterpopup"

    function test_optionButtonsToggleModelFilters() {
        const context = Qt.createQmlObject('import Blockstream.Green 1.0; Context {}', this)
        const model = Qt.createQmlObject('import Blockstream.Green 1.0; AddressModel { filterHasTransactions: false; filterTypes: ["p2wpkh"] }', this)
        const component = Qt.createComponent("../../qml/AddressFilterPopup.qml")
        verify(component.status === Component.Ready, component.errorString())
        const popup = component.createObject(this, { context: context, model: model })
        verify(popup !== null)

        compare(popup.maximumHeight, Number.POSITIVE_INFINITY)

        const buttons = findItems(popup.contentItem, item => item.checkable === true)
        const hasTransactions = buttons.find(button => button.type === undefined)
        const typeButtons = buttons.filter(button => button.type !== undefined)
        verify(hasTransactions !== undefined)
        compare(typeButtons.map(button => button.type), ["p2pkh", "p2sh-p2wpkh", "p2wpkh", "p2tr", "csv", "p2sh", "p2wsh"])

        const checkedTypes = () => typeButtons.filter(button => button.checked).map(button => button.type)
        compare(hasTransactions.checked, false)
        compare(checkedTypes(), ["p2wpkh"])

        const p2tr = typeButtons.find(button => button.type === "p2tr")
        p2tr.clicked()
        compare(model.calls.length, 1)
        compare(model.calls[0], { name: "updateFilterTypes", type: "p2tr", enabled: true })
        compare(checkedTypes(), ["p2wpkh", "p2tr"])

        const p2wpkh = typeButtons.find(button => button.type === "p2wpkh")
        p2wpkh.clicked()
        compare(model.calls.length, 2)
        compare(model.calls[1], { name: "updateFilterTypes", type: "p2wpkh", enabled: false })
        compare(checkedTypes(), ["p2tr"])

        hasTransactions.clicked()
        compare(model.calls.length, 3)
        compare(model.calls[2], { name: "updateFilterHasTransactions", value: true })
        compare(hasTransactions.checked, true)

        popup.destroy()
        model.destroy()
        context.destroy()
    }
}
