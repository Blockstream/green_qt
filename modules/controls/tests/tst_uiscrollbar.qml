import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick
import QtQuick.Controls

GreenTestCase {
    id: self
    name: 'tst_uiscrollbar'
    when: windowShown
    width: 640
    height: 600

    Component {
        id: scroll_component
        Flickable {
            width: 150
            height: 100
            contentWidth: 1000
            contentHeight: 1000
            ScrollBar.horizontal: UiScrollBar {
                policy: ScrollBar.AlwaysOn
            }
            ScrollBar.vertical: UiScrollBar {
                policy: ScrollBar.AlwaysOn
            }
        }
    }
    Component {
        id: form_component
        Item {
            property alias field: field
            property alias nextField: next_field
            property alias flickable: flickable
            width: 300
            height: 200
            Flickable {
                id: flickable
                width: 200
                height: 150
                contentWidth: width
                contentHeight: 600
                UiTextField {
                    id: field
                    width: 160
                    clearable: false
                }
                ScrollBar.vertical: UiScrollBar {
                    policy: ScrollBar.AlwaysOn
                }
            }
            UiTextField {
                id: next_field
                y: 160
                width: 160
                clearable: false
            }
        }
    }

    function test_scrollbarPreservesEditorFocus() {
        const form = createTemporaryObject(form_component, self)
        const bar = form.flickable.ScrollBar.vertical
        compare(bar.focusPolicy, Qt.NoFocus)
        form.field.forceActiveFocus(Qt.TabFocusReason)
        mouseClick(bar, bar.width / 2, bar.height * 0.8)
        verify(form.field.activeFocus)
        keyClick(Qt.Key_A)
        compare(form.field.text, 'a')
        keyClick(Qt.Key_Tab)
        verify(form.nextField.activeFocus)
    }

    function test_scrolling() {
        const flick = createTemporaryObject(scroll_component, self)
        const bar = flick.ScrollBar.vertical
        tryVerify(() => bar.size < 1)
        bar.increase()
        tryVerify(() => flick.contentY > 0)
    }
    function test_keyboardScrolling_data() {
        return [
            { tag: 'vertical', horizontal: false, increaseKey: Qt.Key_Down, decreaseKey: Qt.Key_Up, otherKey: Qt.Key_Right },
            { tag: 'horizontal', horizontal: true, increaseKey: Qt.Key_Right, decreaseKey: Qt.Key_Left, otherKey: Qt.Key_Down }
        ]
    }

    function test_keyboardScrolling(row) {
        const flick = createTemporaryObject(scroll_component, self)
        const bar = row.horizontal ? flick.ScrollBar.horizontal : flick.ScrollBar.vertical
        const coordinate = row.horizontal ? 'contentX' : 'contentY'
        bar.focusPolicy = Qt.TabFocus
        bar.forceActiveFocus(Qt.TabFocusReason)
        keyClick(row.increaseKey)
        tryVerify(() => flick[coordinate] > 0)
        const position = bar.position
        keyClick(row.otherKey)
        compare(bar.position, position)
        keyClick(row.decreaseKey)
        tryCompare(flick, coordinate, 0)
        keyClick(row.decreaseKey)
        compare(bar.position, 0)
        bar.interactive = false
        keyClick(row.increaseKey)
        compare(bar.position, 0)
        bar.interactive = true
        bar.forceActiveFocus(Qt.TabFocusReason)
        bar.enabled = false
        keyClick(row.increaseKey)
        compare(bar.position, 0)
    }

}
