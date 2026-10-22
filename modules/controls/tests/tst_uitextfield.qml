import Blockstream.Theme
import Blockstream.Controls
import Blockstream.Testing
import QtQuick
import QtQuick.Controls
import QtTest

GreenTestCase {
    id: self
    name: 'tst_uitextfield'
    when: windowShown
    width: 600
    height: 700

    Component {
        id: field_component
        UiTextField {}
    }
    Component {
        id: integer_validator
        IntValidator {
            bottom: 0
            top: 9999
        }
    }
    SignalSpy {
        id: cleared_spy
        signalName: 'cleared'
    }
    SignalSpy {
        id: edited_spy
        signalName: 'textEdited'
    }
    SignalSpy {
        id: accepted_spy
        signalName: 'accepted'
    }
    SignalSpy {
        id: changed_spy
        signalName: 'textChanged'
    }

    function createField(properties = {}) {
        const field = createTemporaryObject(field_component, self, properties)
        verify(field !== null)
        cleared_spy.target = field
        edited_spy.target = field
        accepted_spy.target = field
        changed_spy.target = field
        cleared_spy.clear()
        edited_spy.clear()
        accepted_spy.clear()
        changed_spy.clear()
        return field
    }

    function clearButton(field) { return findItems(field, item => item instanceof AbstractButton)[0] }

    function errorPanel(field) { return findItems(field, item => item instanceof Row)[0] }

    function typeText(value) {
        for (const character of value) keyClick(character)
    }

    function cleanup() {
        cleared_spy.target = null
        edited_spy.target = null
        accepted_spy.target = null
        changed_spy.target = null
    }

    function test_nativeEditing() {
        const field = createField()
        field.forceActiveFocus(Qt.TabFocusReason)
        typeText('hello')
        compare(field.text, 'hello')
        compare(edited_spy.count, 5)
        field.select(1, 4)
        compare(field.selectedText, 'ell')
        keyClick(Qt.Key_X)
        compare(field.text, 'hxo')
        keyClick(Qt.Key_Return)
        compare(accepted_spy.count, 1)
        field.text = 'programmatic'
        compare(edited_spy.count, 6)
    }

    function test_clipboardShortcuts() {
        const field = createField({ text: 'copy me' })
        field.forceActiveFocus(Qt.TabFocusReason)
        keySequence(StandardKey.SelectAll)
        compare(field.selectedText, 'copy me')
        keySequence(StandardKey.Copy)
        keyClick(Qt.Key_End)
        keySequence(StandardKey.Paste)
        compare(field.text, 'copy mecopy me')
        keySequence(StandardKey.SelectAll)
        keySequence(StandardKey.Cut)
        compare(field.text, '')
        keySequence(StandardKey.Paste)
        compare(field.text, 'copy mecopy me')
    }

    function test_validatorIsCallerOwned() {
        const validator = createTemporaryObject(integer_validator, self)
        const field = createField({ validator })
        field.forceActiveFocus(Qt.TabFocusReason)
        compare(field.acceptableInput, false)
        typeText('ab12')
        compare(field.text, '12')
        compare(field.acceptableInput, true)
        compare(field.hasError, false)
        field.errorMessage = 'Caller error'
        keyClick(Qt.Key_3)
        compare(field.errorMessage, 'Caller error')
        mouseClick(clearButton(field))
        compare(field.text, '')
        compare(field.acceptableInput, false)
        compare(field.errorMessage, 'Caller error')
        keyClick(Qt.Key_Return)
        compare(accepted_spy.count, 0)
    }

    function test_clearVisibility_data() {
        return [
            { tag: 'empty', text: '', clearable: true, disabled: false, readOnly: false, shown: false },
            { tag: 'filled', text: 'Filled', clearable: true, disabled: false, readOnly: false, shown: true },
            { tag: 'whitespace', text: '   ', clearable: true, disabled: false, readOnly: false, shown: true },
            { tag: 'opt out', text: 'Filled', clearable: false, disabled: false, readOnly: false, shown: false },
            { tag: 'disabled', text: 'Filled', clearable: true, disabled: true, readOnly: false, shown: false },
            { tag: 'read only', text: 'Filled', clearable: true, disabled: false, readOnly: true, shown: false }
        ]
    }

    function test_clearVisibility(row) {
        const field = createField({ text: row.text, clearable: row.clearable, disabled: row.disabled, readOnly: row.readOnly })
        compare(clearButton(field).visible, row.shown)
        compare(clearButton(field).enabled, row.shown)
    }

    function test_clearActivation_data() {
        const keys = [{ tag: 'pointer', key: 0 }, { tag: 'space', key: Qt.Key_Space }]
        const rows = []
        for (const row of keys) {
            rows.push({ tag: `large-${row.tag}`, key: row.key, size: UiTextField.Large })
            rows.push({ tag: `medium-${row.tag}`, key: row.key, size: UiTextField.Medium })
            rows.push({ tag: `small-${row.tag}`, key: row.key, size: UiTextField.Small })
        }
        return rows
    }

    function test_clearActivation(row) {
        const field = createField({ text: 'Filled', size: row.size })
        const button = clearButton(field)
        field.forceActiveFocus(Qt.TabFocusReason)
        if (row.key) {
            keyClick(Qt.Key_Tab)
            compare(button.activeFocus, true)
            keyClick(Qt.Key_Backtab)
            compare(field.activeFocus, true)
            keyClick(Qt.Key_Tab)
            compare(button.activeFocus, true)
            keyClick(row.key)
        } else {
            mouseClick(button)
        }
        compare(field.text, '')
        compare(cleared_spy.count, 1)
        compare(changed_spy.count, 1)
        compare(edited_spy.count, 0)
        compare(accepted_spy.count, 0)
        compare(field.activeFocus, true)
        compare(button.visible, false)
    }

    function test_unavailableBlocksEditing_data() {
        return [{ tag: 'disabled', disabled: true, readOnly: false }, { tag: 'read only', disabled: false, readOnly: true }]
    }

    function test_unavailableBlocksEditing(row) {
        const field = createField({ text: 'Retained', disabled: row.disabled, readOnly: row.readOnly })
        const button = clearButton(field)
        mouseClick(field, 30, 30)
        typeText('changed')
        keyClick(Qt.Key_Backspace)
        mouseClick(button)
        button.clicked()
        compare(field.text, 'Retained')
        compare(cleared_spy.count, 0)
        compare(edited_spy.count, 0)
        if (row.readOnly) {
            field.forceActiveFocus(Qt.TabFocusReason)
            keySequence(StandardKey.SelectAll)
            compare(field.selectedText, 'Retained')
            keySequence(StandardKey.Copy)
            keySequence(StandardKey.Cut)
            compare(field.text, 'Retained')
        }
    }

    function test_disableCancelsClearPress() {
        const field = createField({ text: 'Retained' })
        const button = clearButton(field)
        mousePress(button)
        field.disabled = true
        mouseRelease(button)
        compare(field.text, 'Retained')
        compare(cleared_spy.count, 0)
        field.disabled = false
        mouseClick(button)
        compare(cleared_spy.count, 1)
    }

    function test_longTextEditing() {
        const text = '0123456789'.repeat(20)
        const field = createField({ width: 160, text })
        field.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_End)
        typeText('end')
        compare(field.text, text + 'end')
        keyClick(Qt.Key_Home)
        typeText('start')
        compare(field.text, 'start' + text + 'end')
        keySequence(StandardKey.SelectAll)
        compare(field.selectedText, field.text)
        keyClick(Qt.Key_Backspace)
        compare(field.text, '')
    }

    function test_errorMessageIsCallerOwned() {
        const field = createField({ text: 'Filled', errorMessage: 'Caller error' })
        compare(field.Accessible.description, 'Caller error')
        field.forceActiveFocus(Qt.TabFocusReason)
        typeText('x')
        compare(field.errorMessage, 'Caller error')
        mouseClick(clearButton(field))
        compare(field.errorMessage, 'Caller error')
        compare(field.Accessible.description, 'Caller error')
        field.errorMessage = 'Updated error'
        compare(field.Accessible.description, 'Updated error')
        field.errorMessage = ''
        compare(field.Accessible.description, '')
    }

    function test_replacingPendingError() {
        const field = createField({ errorMessage: 'Initial error' })
        const panel = errorPanel(field)
        compare(panel.expanded, false)

        field.errorMessage = 'Replacement error'
        compare(panel.expanded, false)
        tryCompare(panel, 'expanded', true)
        compare(panel.displayedMessage, 'Replacement error')
        compare(field.Accessible.description, 'Replacement error')
    }

    function test_clearingPendingError() {
        const field = createField({ errorMessage: 'Initial error' })
        const panel = errorPanel(field)
        compare(panel.expanded, false)

        field.errorMessage = ''
        // Wait beyond the reveal delay to catch a stale timer reopening the error.
        wait(250)
        compare(panel.expanded, false)
        compare(field.hasError, false)
        compare(field.Accessible.description, '')
    }
    Component {
        id: composed_component
        UiTextField {
            text: 'Filled'
            trailingItem: UiIconButton {
                text: 'Copy'
                iconName: Theme.icons.copy
            }
        }
    }
    function test_composedFocus() {
        const field = createTemporaryObject(composed_component, self)
        field.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Tab)
        compare(field.trailingItem.activeFocus, true)
        keyClick(Qt.Key_Tab)
        const clear = findItems(field, item => item instanceof AbstractButton && item !== field.trailingItem)[0]
        compare(clear.activeFocus, true)
        keyClick(Qt.Key_Backtab)
        compare(field.trailingItem.activeFocus, true)
        keyClick(Qt.Key_Backtab)
        compare(field.activeFocus, true)
        verify(field.rightPadding > field.trailingItem.width)
    }
    function test_clearActionId() {
        const field = createField({text: 'value'})
        field.Accessible.id = 'field'
        const clear = clearButton(field)
        compare(clear.Accessible.id, 'field_clear')
        field.Accessible.id = 'changed'
        compare(clear.Accessible.id, 'changed_clear')
        field.Accessible.id = ''
        compare(clear.Accessible.id, '')
    }

    function test_slotReplacementAndRemoval_data() {
        return [{tag: 'leading', slot: 'leadingItem'}, {tag: 'trailing', slot: 'trailingItem'}]
    }
    function test_slotReplacementAndRemoval(row) {
        const host = createTemporaryObject(focus_host_component, self)
        const field = host.field
        const original = field[row.slot]
        const replacement = createTemporaryObject(action_component, field)
        original.forceActiveFocus(Qt.TabFocusReason)
        field[row.slot] = replacement
        compare(original.parent, null)
        verify(!original.activeFocus)
        verify(replacement.parent !== field && replacement.parent !== null)
        field[row.slot] = null
        compare(replacement.parent, null)
        field[row.slot] = original
        verify(original.parent !== field && original.parent !== null)
        verify(original.visible)
        verify(original.enabled)
        original.forceActiveFocus(Qt.TabFocusReason)
        verify(original.activeFocus)
    }
    Component {
        id: action_component
        UiIconButton {
            text: 'Replacement'
            iconName: Theme.icons.copy
        }
    }

    function test_actionFocusBorder() {
        const host = createTemporaryObject(focus_host_component, self)
        for (const action of [host.field.leadingItem, host.field.trailingItem]) {
            action.forceActiveFocus(Qt.TabFocusReason)
            verify(action.activeFocus)
            compare(host.field.borderColor, host.field.colors.borderBrand)
        }
    }

    Component {
        id: focus_host_component
        Item {
            property alias before: before_field
            property alias field: composed_field
            property alias after: after_field
            property bool leadingAvailable: true
            property bool trailingAvailable: true
            property bool clearAvailable: true
            property bool leadingFocusable: true

            id: focus_host
            width: 400
            height: 240
            UiTextField {
                id: before_field
                width: 300
                clearable: false
            }
            UiTextField {
                id: composed_field
                y: 80
                width: 300
                text: 'Filled'
                clearable: focus_host.clearAvailable
                leadingItem: UiIconButton {
                    text: 'Select all'
                    iconName: Theme.icons.check
                    visible: focus_host.leadingAvailable
                    focusPolicy: focus_host.leadingFocusable ? Qt.StrongFocus : Qt.NoFocus
                }
                trailingItem: UiIconButton {
                    text: 'Copy'
                    iconName: Theme.icons.copy
                    enabled: focus_host.trailingAvailable
                }
            }
            UiTextField {
                id: after_field
                y: 160
                width: 300
                clearable: false
            }
        }
    }

    function test_composedFocusTraversal_data() {
        return [
            { tag: 'all actions', leading: true, trailing: true, clearable: true },
            { tag: 'leading only', leading: true, trailing: false, clearable: false },
            { tag: 'trailing only', leading: false, trailing: true, clearable: false },
            { tag: 'no actions', leading: false, trailing: false, clearable: false },
            { tag: 'clear only', leading: false, trailing: false, clearable: true },
            { tag: 'non-focusable leading', leading: true, trailing: false, clearable: false, leadingFocusable: false }
        ]
    }

    function test_composedFocusTraversal(row) {
        const host = createTemporaryObject(focus_host_component, self, {
            leadingAvailable: row.leading,
            trailingAvailable: row.trailing,
            clearAvailable: row.clearable,
            leadingFocusable: row.leadingFocusable ?? true
        })
        const field = host.field
        const clear = findItems(field, item => item instanceof AbstractButton && item !== field.leadingItem && item !== field.trailingItem)[0]
        const order = [host.before, field]
        if (row.leading && host.leadingFocusable) order.push(field.leadingItem)
        if (row.trailing) order.push(field.trailingItem)
        if (row.clearable) order.push(clear)
        order.push(host.after)

        host.before.forceActiveFocus(Qt.TabFocusReason)
        for (let index = 1; index < order.length; ++index) {
            keyClick(Qt.Key_Tab)
            compare(order[index].activeFocus, true, 'Forward focus at index ' + index)
        }
        // Start inside the field: native macOS reverse entry can skip buttons
        // when the system is configured to tab only to text controls.
        order[order.length - 2].forceActiveFocus(Qt.BacktabFocusReason)
        for (let index = order.length - 3; index >= 0; --index) {
            keyClick(Qt.Key_Backtab)
            compare(order[index].activeFocus, true, 'Backward focus at index ' + index)
        }

        host.leadingAvailable = false
        host.trailingAvailable = false
        field.clear()
        field.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Tab)
        compare(host.after.activeFocus, true)
        field.forceActiveFocus(Qt.BacktabFocusReason)
        keyClick(Qt.Key_Backtab)
        compare(host.before.activeFocus, true)

        field.leadingItem = null
        field.trailingItem = null
        field.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Tab)
        compare(host.after.activeFocus, true)
    }
}
