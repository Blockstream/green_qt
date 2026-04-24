import QtQuick
import QtTest
import Blockstream.Green

GreenTestCase {
    name: "tst_addresstypelabel"

    function test_localizedTextFromAddressType() {
        const address = Qt.createQmlObject('import Blockstream.Green 1.0; Address { type: "p2tr" }', this)
        const component = Qt.createComponent("../../qml/AddressTypeLabel.qml")
        verify(component.status === Component.Ready, component.errorString())
        const label = component.createObject(this, { address: address })
        verify(label !== null)
        compare(label.text, "p2tr")
        compare(label.font.pixelSize, 12)
        label.destroy()
        address.destroy()
    }
}
