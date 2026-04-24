import QtQuick
import QtTest

GreenTestCase {
    name: "tst_filterpopup"

    function test_defaultsAndPositioning() {
        const parentItem = Qt.createQmlObject("import QtQuick; Item { width: 400; height: 100 }", this)
        const component = Qt.createComponent("../../qml/FilterPopup.qml")
        verify(component.status === Component.Ready, component.errorString())
        const popup = component.createObject(parentItem)
        verify(popup !== null)

        compare(popup.padding, 8)
        compare(popup.spacing, 4)
        compare(popup.pointerX, 1)
        compare(popup.pointerXOffset, -200)

        // Popup position is only resolved while open.
        popup.open()
        compare(popup.x, 400 - popup.width)
        compare(popup.y, 108)

        popup.destroy()
        parentItem.destroy()
    }
}
