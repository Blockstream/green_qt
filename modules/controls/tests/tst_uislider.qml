import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uislider'
    when: windowShown
    width: 640
    height: 600
    Component {
        id: slider_component
        UiSlider {
            from: 0
            to: 10
            stepSize: 2
        }
    }
    function test_slider() {
        const slider = createTemporaryObject(slider_component, self)
        slider.forceActiveFocus()
        keyClick(Qt.Key_Right)
        compare(slider.value, 2)
        slider.disabled = true
        keyClick(Qt.Key_Right)
        compare(slider.value, 2)
    }
    function test_palettes_data() {
        return [{tag: 'light', colors: Theme.lightColors}, {tag: 'dark', colors: Theme.darkColors}]
    }
    function test_palettes(row) {
        const item = createTemporaryObject(slider_component, self, {colors: row.colors})
        verify(item !== null)
        verify(waitForRendering(item))
    }

    Component {
        id: bound_component
        Item {
            property real amount: 4
            property alias slider: control
            UiSlider {
                id: control
                from: 0
                to: 10
                stepSize: 2
                value: parent.amount
                onMoved: parent.amount = value
            }
        }
    }
    function test_callerBinding() {
        const host = createTemporaryObject(bound_component, self)
        host.slider.forceActiveFocus()
        keyClick(Qt.Key_Right)
        compare(host.amount, 6)
        host.amount = 8
        compare(host.slider.value, 8)
    }

}
