import QtQuick
import QtTest

GreenTestCase {
    name: "tst_transactionprogress"

    function test_loaderActiveUntilCompletion() {
        const component = Qt.createComponent("../../qml/TransactionProgress.qml")
        verify(component.status === Component.Ready, component.errorString())
        const progress = component.createObject(this, { current: 1, max: 3, icon: "", width: 32, height: 32 })
        verify(progress !== null)

        const loader = findItems(progress, item => item.sourceComponent !== undefined)[0]
        const check = findItems(progress, item => item.sourceSize !== undefined)[0]
        verify(loader !== undefined)
        verify(check !== undefined)

        compare(loader.active, true)
        verify(loader.item !== null)
        compare(loader.item.children[0].text, "1")
        compare(loader.item.children[1].text, "/3")
        compare(check.opacity, 0)
        compare(loader.opacity, 1)

        progress.current = 3
        compare(loader.active, false)
        tryCompare(check, "opacity", 1)
        compare(loader.opacity, 0)

        progress.destroy()
    }
}
