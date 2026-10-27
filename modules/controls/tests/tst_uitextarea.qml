import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick
import QtQuick.Controls as Controls
import QtTest

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
    function test_emptyDefaultHeight() {
        const area = createTemporaryObject(area_component, self)
        compare(area.text, '')
        compare(area.clearable, true)
        compare(area.actionsHeight, 44)
        compare(area.implicitHeight, 128)
        compare(area.height, 128)
        verify(area.height - area.topPadding - area.bottomPadding >= 3 * Theme.typography.bodyM.lineHeight)
        area.clearable = false
        compare(area.height, 128)
    }
    function test_defaultReservesClearAction() {
        const area = createTemporaryObject(area_component, self, {text: 'Retained'})
        compare(area.clearable, true)
        verify(area.clearVisible)
        compare(area.actionsHeight, 44)
        area.text = ''
        verify(!area.clearVisible)
        compare(area.actionsHeight, 44)
        area.clearable = false
        compare(area.actionsHeight, 0)
        compare(area.bottomPadding, 12)
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
        const panel = findItems(area, item => item instanceof Row && item.revealProgress !== undefined)[0]
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

    function test_footerPreservesRoundedCorners_data() {
        return [{tag: 'normal', error: ''}, {tag: 'validation', error: 'Validation error'}]
    }

    function test_footerPreservesRoundedCorners(row) {
        const host = createTemporaryObject(clipping_host_component, self)
        const area = host.area
        area.text = 'Sample QR result'
        area.forceActiveFocus()
        area.errorMessage = row.error
        if (row.error) {
            const panel = findItems(area, item => item instanceof Row && item.revealProgress !== undefined)[0]
            tryCompare(panel, 'revealProgress', 1)
        }
        // Keep geometry fixed when hiding the footer for the reference image.
        area.height = area.implicitHeight
        const footer = area.children.find(item => item.z === 1 && item.clip)
        verify(footer !== undefined)
        const actual = grabImage(host)
        footer.visible = false
        const reference = grabImage(host)
        const scale = actual.width / host.width
        for (let y = Math.floor((area.y + area.height - 8) * scale); y < (area.y + area.height) * scale; ++y) {
            for (const corner_x of [area.x, area.x + area.width - 8]) {
                for (let x = Math.floor(corner_x * scale); x < (corner_x + 8) * scale; ++x) {
                    for (const channel of ['red', 'green', 'blue']) {
                        verify(Math.abs(actual[channel](x, y) - reference[channel](x, y)) <= 2,
                               'Footer changed the rounded corner at ' + x + ', ' + y)
                    }
                }
            }
        }
    }

    function test_partialValidationDoesNotPaintBelowField() {
        const host = createTemporaryObject(clipping_host_component, self)
        const area = host.area
        area.errorMessage = 'A long validation message that wraps across several lines. '.repeat(3)
        const panel = findItems(area, item => item instanceof Row && item.revealProgress !== undefined)[0]
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

    Component {
        id: actions_area_component
        UiTextArea {
            property int triggeredCount: 0

            width: 260
            clearable: true
            id: area
            actions: Row {
                UiIconButton {
                    text: 'Insert sample'
                    iconName: Theme.icons.clipboard
                    variant: UiButton.Neutral
                    size: UiButton.Small
                    onClicked: {
                        ++area.triggeredCount
                        area.insert(area.cursorPosition, 'Sample')
                    }
                }
            }
        }
    }
    Component {
        id: cleared_spy_component
        SignalSpy { signalName: 'cleared' }
    }
    function test_customActionAndClear() {
        const area = createTemporaryObject(actions_area_component, self)
        const spy = createTemporaryObject(cleared_spy_component, self, {target: area})
        const buttons = findItems(area, item => item instanceof UiIconButton)
        const insert_button = buttons.find(button => button.text === 'Insert sample')
        const clear_button = buttons.find(button => button.iconName === Theme.icons.xCircle)
        verify(insert_button !== undefined)
        verify(clear_button !== undefined)
        const initial_height = area.height
        verify(!clear_button.visible)
        mouseClick(insert_button)
        compare(area.triggeredCount, 1)
        compare(area.text, 'Sample')
        verify(clear_button.visible)
        compare(area.height, initial_height)
        verify(area.bottomPadding >= clear_button.height + 12)
        mouseClick(clear_button)
        compare(area.text, '')
        compare(spy.count, 1)
        verify(area.activeFocus)
        verify(!clear_button.visible)
    }
    function test_customActionFocusKeepsBorder() {
        const area = createTemporaryObject(actions_area_component, self)
        const action = findItems(area, item => item instanceof UiIconButton && item.text === 'Insert sample')[0]
        action.forceActiveFocus(Qt.TabFocusReason)
        verify(action.activeFocus)
        verify(!area.activeFocus)
        compare(area.borderColor, area.colors.borderBrand)
        area.invalid = true
        compare(area.borderColor, area.colors.feedbackNegativeStroke)
    }
    function test_clearUnavailable_data() {
        return [
            {tag: 'clear-disabled', clearable: false, readOnly: false, disabled: false},
            {tag: 'read-only', clearable: true, readOnly: true, disabled: false},
            {tag: 'disabled', clearable: true, readOnly: false, disabled: true}
        ]
    }
    function test_actionSlotResizes() {
        const area = createTemporaryObject(actions_area_component, self, {clearable: false})
        compare(area.actions.length, 1)
        const row = area.actions[0]
        verify(row.parent !== area)
        verify(area.actionsHeight > 0)
        row.height = 64
        tryCompare(area, 'actionsHeight', 72)
    }
    function test_actionInsets() {
        const area = createTemporaryObject(actions_area_component, self, {text: 'Filled'})
        const action = findItems(area, item => item instanceof UiIconButton && item.text === 'Insert sample')[0]
        const clear = findItems(area, item => item instanceof UiIconButton && item.iconName === Theme.icons.xCircle)[0]
        verify(waitForPolish(clear.parent))
        compare(action.mapToItem(area, 0, 0).x, area.leftPadding / 2)
        const position = clear.mapToItem(area, 0, 0)
        compare(area.width - position.x - clear.width, area.rightPadding / 2)
        compare(area.fieldHeight - position.y - clear.height, area.rightPadding / 2)
    }
    Component {
        id: focus_host_component
        Item {
            property alias before: before_field
            property alias area: area
            property alias after: after_field
            property alias first: first_action
            property alias second: second_action

            width: 400
            height: 400
            UiTextField {
                id: before_field
                width: 300
                clearable: false
            }
            UiTextArea {
                id: area
                y: 70
                width: 300
                text: 'Filled'
                actions: Row {
                    UiIconButton {
                        id: first_action
                        text: 'First'
                        iconName: Theme.icons.copy
                    }
                    Item {
                        width: second_action.width
                        height: second_action.height
                        UiIconButton {
                            id: second_action
                            text: 'Second'
                            iconName: Theme.icons.clipboard
                        }
                    }
                }
            }
            UiTextField {
                id: after_field
                y: 300
                width: 300
                clearable: false
            }
        }
    }

    function test_tabLeavesEditorWithoutChangingText() {
        const host = createTemporaryObject(focus_host_component, self)
        const area = host.area
        area.forceActiveFocus(Qt.TabFocusReason)
        const next = area.nextItemInFocusChain()
        verify(next !== area)
        keyClick(Qt.Key_Tab)
        compare(area.text, 'Filled')
        verify(next.activeFocus)
        verify(!area.activeFocus)
    }

    function test_hiddenClearFocus_data() {
        return [
            {tag: 'text reset while focused', readOnly: false, focused: true},
            {tag: 'read-only while focused', readOnly: true, focused: true},
            {tag: 'text reset without focus', readOnly: false, focused: false},
            {tag: 'read-only without focus', readOnly: true, focused: false}
        ]
    }

    function test_hiddenClearFocus(row) {
        const host = createTemporaryObject(focus_host_component, self)
        const clear = findItems(host.area, item => item instanceof UiIconButton && item.iconName === Theme.icons.xCircle)[0]
        const focused = row.focused ? clear : host.before
        focused.forceActiveFocus(Qt.TabFocusReason)
        verify(focused.activeFocus)
        if (row.readOnly) host.area.readOnly = true
        else host.area.text = ''
        verify(!clear.visible)
        verify(!clear.activeFocus)
        verify(row.focused ? host.area.activeFocus : host.before.activeFocus)
    }

    function test_disabledClearDoesNotRefocusEditor() {
        const area = createTemporaryObject(area_component, self, {text: 'Filled'})
        const clear = findItems(area, item => item instanceof UiIconButton && item.iconName === Theme.icons.xCircle)[0]
        clear.forceActiveFocus(Qt.TabFocusReason)
        verify(clear.activeFocus)
        area.disabled = true
        verify(!clear.activeFocus)
        verify(!area.activeFocus)
    }

    function test_nativeActionFocusTraversal() {
        const host = createTemporaryObject(focus_host_component, self)
        const clear = findItems(host.area, item => item instanceof UiIconButton && item.iconName === Theme.icons.xCircle)[0]
        for (const action of [host.first, host.second, clear]) {
            action.forceActiveFocus(Qt.TabFocusReason)
            const next = action.nextItemInFocusChain()
            keyClick(Qt.Key_Tab)
            verify(next.activeFocus)
            action.forceActiveFocus(Qt.BacktabFocusReason)
            const previous = action.nextItemInFocusChain(false)
            keyClick(Qt.Key_Backtab)
            verify(previous.activeFocus)
        }
    }

    component ScrollingTextArea: UiTextArea {
        property int triggeredCount: 0

        id: scrolling_area
        text: 'Long line of text for scrolling.\n'.repeat(80)
        actions: Row {
            UiIconButton {
                text: 'Test action'
                iconName: Theme.icons.copy
                onClicked: ++scrolling_area.triggeredCount
            }
        }
    }

    Component {
        id: scrollview_area_component
        Controls.ScrollView {
            property alias area: scrolling_area

            width: 300
            height: 200
            ScrollingTextArea {
                id: scrolling_area
            }
        }
    }

    Component {
        id: flickable_area_component
        Flickable {
            property alias area: scrolling_area

            width: 300
            height: 200
            clip: true
            Controls.TextArea.flickable: ScrollingTextArea {
                id: scrolling_area
            }
        }
    }

    function test_longTextKeepsActionsVisible_data() {
        return [
            {tag: 'ScrollView', component: scrollview_area_component, error: ''},
            {tag: 'Flickable', component: flickable_area_component, error: ''},
            {tag: 'ScrollView validation', component: scrollview_area_component, error: 'Validation error'},
            {tag: 'Flickable validation', component: flickable_area_component, error: 'Validation error'}
        ]
    }

    function test_longTextKeepsActionsVisible(row) {
        const view = createTemporaryObject(row.component, self)
        const area = view.area
        area.errorMessage = row.error
        if (row.error) tryVerify(() => area.errorHeight > 0)
        if (row.error) {
            const panel = findItems(view, item => item instanceof Row && item.revealProgress !== undefined)[0]
            tryCompare(panel, 'revealProgress', 1)
        }
        const flickable = view instanceof Flickable ? view : view.contentItem
        tryVerify(() => flickable.contentHeight > view.height * 2)
        const buttons = findItems(view, item => item instanceof UiIconButton)
        const action = buttons.find(button => button.text === 'Test action')
        const clear = buttons.find(button => button.iconName === Theme.icons.xCircle)
        verify(waitForPolish(clear.parent))
        const initial_positions = [action, clear].map(button => button.mapToItem(view, 0, 0).y)
        for (const fraction of [0, 0.5, 1]) {
            const scroll_y = Math.round(fraction * (flickable.contentHeight - flickable.height))
            flickable.contentY = scroll_y
            compare(flickable.contentY, scroll_y)
            for (const [index, button] of [action, clear].entries()) {
                const position = button.mapToItem(view, 0, 0)
                verify(position.y >= 0 && position.y + button.height <= view.height,
                       'Action must stay inside the viewport while scrolling')
                compare(position.y, initial_positions[index])
                verify(position.y + button.height <= view.height - area.errorHeight)
            }
            mouseClick(action)
        }
        compare(area.triggeredCount, 3)
        area.disabled = true
        verify(!action.enabled)
        verify(!clear.visible)
        area.disabled = false
        flickable.contentY = 0
        mouseClick(clear)
        compare(area.text, '')
        verify(area.activeFocus)
        verify(!clear.visible)
    }

    function test_clearUnavailable(row) {
        const area = createTemporaryObject(area_component, self, {
            text: 'Retained', clearable: row.clearable, readOnly: row.readOnly, disabled: row.disabled
        })
        verify(!area.clearVisible)
        compare(area.text, 'Retained')
    }
}
