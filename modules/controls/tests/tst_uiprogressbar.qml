import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uiprogressbar'
    when: windowShown
    width: 640
    height: 600
    Component {
        id: progress_component
        UiProgressBar {}
    }
    function test_rangeAndIndeterminate() {
        const bar = createTemporaryObject(progress_component, self, {from: 0, to: 10, value: 5})
        compare(bar.position, 0.5)
        bar.value = 20
        compare(bar.position, 1)
        bar.value = -1
        compare(bar.position, 0)
        bar.indeterminate = true
        const fill = bar.contentItem.children[0]
        tryVerify(() => fill.phase > 0)
        bar.visible = false
        const stopped = fill.phase
        wait(100)
        compare(fill.phase, stopped)
    }

    function test_palettes_data() {
        return [{tag: 'light', colors: Theme.lightColors}, {tag: 'dark', colors: Theme.darkColors}]
    }
    function test_palettes(row) {
        const item = createTemporaryObject(progress_component, self, {colors: row.colors})
        verify(item !== null)
        verify(waitForRendering(item))
    }

}
