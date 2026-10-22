import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uitextarea'
    when: windowShown
    width: 640
    height: 600
    Component {
        id: area_component
        UiTextArea {
            width: 220
        }
    }
    function test_multilineEditing() {
        const area = createTemporaryObject(area_component, self)
        area.forceActiveFocus()
        keyClick(Qt.Key_A)
        keyClick(Qt.Key_Return)
        keyClick(Qt.Key_B)
        compare(area.text, 'a\nb')
    }
    function test_readOnlySelection() {
        const area = createTemporaryObject(area_component, self, {text: 'a\nb', readOnly: true})
        area.forceActiveFocus()
        area.selectAll()
        compare(area.selectedText, area.text)
        keyClick(Qt.Key_X)
        compare(area.text, 'a\nb')
    }
    function test_validationWrapAndCollapse() {
        const area = createTemporaryObject(area_component, self)
        area.errorMessage = 'An error that wraps across multiple lines '.repeat(3)
        tryVerify(() => area.errorHeight > 0)
        compare(area.Accessible.description, area.errorMessage)
        area.errorMessage = ''
        tryCompare(area, 'errorHeight', 0)
    }
    function test_disabledRetainsText() {
        const area = createTemporaryObject(area_component, self, {text: 'Retained', disabled: true})
        mouseClick(area)
        keyClick(Qt.Key_X)
        compare(area.text, 'Retained')
    }
    function test_errorBackgroundDuringCollapse() {
        const area = createTemporaryObject(area_component, self)
        area.errorMessage = 'Validation error'
        const panel = findItems(area, item => item instanceof Row)[0]
        tryCompare(panel, 'revealProgress', 1)
        area.errorMessage = ''
        // Freeze an intermediate frame instead of depending on animation timing.
        panel.revealProgress = 0.5
        tryCompare(panel, 'revealProgress', 0.5)
        compare(area.background.color, area.colors.feedbackNegativeFill)
        compare(area.background.border.color, area.colors.feedbackNegativeStroke)
    }
    function test_hoverBorderPrecedence() {
        const area = createTemporaryObject(area_component, self)
        mouseMove(area, 20, 20)
        tryCompare(area, 'hovered', true)
        compare(area.background.children[0].border.color, area.colors.borderBold)
        area.forceActiveFocus()
        compare(area.background.children[0].border.color, area.colors.borderBrand)
        area.disabled = true
        compare(area.background.children[0].border.color, area.colors.borderSubtle)
        area.errorMessage = 'Validation error'
        compare(area.background.children[0].border.color, area.colors.feedbackNegativeStroke)
    }
    function test_palettes_data() {
        return [{tag: 'light', colors: Theme.lightColors}, {tag: 'dark', colors: Theme.darkColors}]
    }
    function test_palettes(row) {
        const item = createTemporaryObject(area_component, self, {colors: row.colors})
        verify(item !== null)
        verify(waitForRendering(item))
    }

    Component {
        id: clipping_host_component
        Rectangle {
            property alias area: area

            width: 260
            height: 400
            color: '#ff00ff'
            UiTextArea {
                id: area
                x: 10
                y: 10
                width: 220
            }
        }
    }

    function test_partialValidationDoesNotPaintBelowField() {
        const host = createTemporaryObject(clipping_host_component, self)
        const area = host.area
        area.errorMessage = 'A long validation message that wraps across several lines. '.repeat(3)
        const panel = findItems(area, item => item instanceof Row)[0]
        tryCompare(panel, 'revealProgress', 1)
        // Freeze a partial reveal so the pixel assertion is independent of frame timing.
        panel.revealProgress = 0.25
        tryCompare(panel, 'revealProgress', 0.25)
        const image = grabImage(host)
        const scale = image.width / host.width
        const top = Math.ceil((area.y + area.height + 1) * scale)
        const bottom = Math.floor(Math.min(host.height, area.y + area.fieldHeight + panel.implicitHeight) * scale)
        for (let y = top; y < bottom; ++y) {
            for (let x = Math.ceil(area.x * scale); x < (area.x + area.width) * scale; ++x) {
                verify(image.red(x, y) === 255 && image.green(x, y) === 0 && image.blue(x, y) === 255,
                       'Validation painted outside the reserved field height')
            }
        }
    }

}
