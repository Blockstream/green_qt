import QtQuick
import QtTest
import Blockstream.Green

GreenTestCase {
    name: "tst_accountfilterpopup"

    function createAccount(properties) {
        const account = Qt.createQmlObject('import Blockstream.Green 1.0; Account {}', this)
        Object.assign(account, properties)
        return account
    }

    function test_initialPartitioning() {
        const a1 = createAccount({ pointer: 1, name: "A1" })
        const a2 = createAccount({ pointer: 2, name: "A2" })
        const a3 = createAccount({ pointer: 3, name: "A3", hidden: true })

        const context = Qt.createQmlObject('import Blockstream.Green 1.0; Context {}', this)
        context.accounts = [a1, a2, a3]

        const model = Qt.createQmlObject('import Blockstream.Green 1.0; ContextModel {}', this)
        model.filterAccounts = [a2]

        const popupComponent = Qt.createComponent("../../qml/AccountFilterPopup.qml")
        verify(popupComponent.status === Component.Ready, popupComponent.errorString())
        const popup = popupComponent.createObject(this, { context: context, model: model })
        verify(popup !== null)

        compare(popup.filterAccounts.length, 1)
        compare(popup.filterAccounts[0], a2)
        compare(popup.accounts.length, 1)
        compare(popup.accounts[0], a1)

        // Filtered accounts come first, then the remaining visible ones.
        const delegates = findItems(popup.contentItem, item => item.account !== undefined)
        compare(delegates.length, 2)
        compare(delegates[0].account, a2)
        compare(delegates[1].account, a1)

        delegates[1].clicked()
        compare(model.calls.length, 1)
        compare(model.calls[0].name, "updateFilterAccounts")
        compare(model.calls[0].account, a1)
        compare(model.calls[0].enabled, true)

        delegates[0].clicked()
        compare(model.calls.length, 2)
        compare(model.calls[1].account, a2)
        compare(model.calls[1].enabled, false)

        popup.destroy()
        model.destroy()
        context.destroy()
        a1.destroy()
        a2.destroy()
        a3.destroy()
    }
}
