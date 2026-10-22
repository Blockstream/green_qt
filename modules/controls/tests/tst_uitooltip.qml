import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uitooltip'
    when: windowShown
    width: 640
    height: 600
    Component {
        id: tooltip_component
        UiToolTip {
            text: 'A long hint'
            delay: 20
            timeout: 60
        }
    }
    function test_tooltip() {
        const tooltip = createTemporaryObject(tooltip_component, self)
        tooltip.show('Hint')
        tryCompare(tooltip, 'visible', true)
        tryCompare(tooltip, 'visible', false)
    }
    function test_hideCancelsPendingShow() {
        const tooltip = createTemporaryObject(tooltip_component, self, {delay: 100})
        tooltip.show('Pending')
        tooltip.hide()
        wait(150)
        compare(tooltip.visible, false)
    }

}
