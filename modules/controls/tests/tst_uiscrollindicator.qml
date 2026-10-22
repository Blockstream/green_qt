import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick
import QtQuick.Controls

GreenTestCase {
    id: self
    name: 'tst_uiscrollindicator'
    when: windowShown
    width: 640
    height: 600

    Component {
        id: scroll_component
        Flickable {
            width: 150
            height: 100
            contentWidth: 150
            contentHeight: 1000
            ScrollIndicator.vertical: UiScrollIndicator {}
        }
    }
    function test_tracksFlickable() {
        const flick = createTemporaryObject(scroll_component, self)
        const indicator = flick.ScrollIndicator.vertical
        tryCompare(indicator, 'size', 0.1)
        flick.contentY = 450
        tryCompare(indicator, 'position', 0.45)
        flick.contentHeight = flick.height
        tryCompare(indicator, 'size', 1)
    }
}
