import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uicircularprogress'
    when: windowShown
    width: 640
    height: 600
    Component {
        id: circle_component
        UiCircularProgress {}
    }
    function test_progress() {
        const circle = createTemporaryObject(circle_component, self, { from: 0, to: 6, value: 3 })
        compare(circle.position, 0.5)
        circle.value = 10
        compare(circle.position, 1)
        circle.value = -1
        compare(circle.position, 0)
        circle.to = 0
        compare(circle.position, 0)
        circle.colors = Theme.lightColors
    }
    function test_palettes_data() {
        return [{tag: 'light', colors: Theme.lightColors}, {tag: 'dark', colors: Theme.darkColors}]
    }
    function test_palettes(row) {
        const item = createTemporaryObject(circle_component, self, {colors: row.colors})
        verify(item !== null)
        verify(waitForRendering(item))
    }

}
