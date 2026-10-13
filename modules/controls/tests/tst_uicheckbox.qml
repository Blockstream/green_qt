import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtTest

GreenTestCase {
    id: self
    name: "tst_uicheckbox"
    when: windowShown
    width: 200
    height: 100

    property bool accepted: false
    property bool available: true

    Component {
        id: checkbox_component
        UiCheckbox {
            text: "Accept terms"
            disabled: !self.available
            checked: self.accepted
            onToggled: self.accepted = checked
        }
    }

    Component {
        id: tristate_component
        UiCheckbox {
            text: "Select all"
            tristate: true
        }
    }

    SignalSpy {
        id: toggle_spy
        signalName: "toggled"
    }

    function createCheckbox(component = checkbox_component, properties = {}) {
        const checkbox = createTemporaryObject(component, self, properties)
        verify(checkbox !== null)
        toggle_spy.target = checkbox
        toggle_spy.clear()
        return checkbox
    }

    function cleanup() {
        toggle_spy.target = null
        self.accepted = false
        self.available = true
    }

    function test_mouseToggle() {
        const checkbox = createCheckbox()
        mouseClick(checkbox)
        verify(self.accepted)
        compare(checkbox.checkState, Qt.Checked)
        mouseClick(checkbox)
        verify(!self.accepted)
        compare(checkbox.checkState, Qt.Unchecked)
        compare(toggle_spy.count, 2)
    }

    function test_checkedFollowsBinding() {
        const checkbox = createCheckbox()
        self.accepted = true
        compare(checkbox.checkState, Qt.Checked)
        self.accepted = false
        compare(checkbox.checkState, Qt.Unchecked)
    }

    function test_keyboardActivation() {
        const checkbox = createCheckbox()
        checkbox.forceActiveFocus(Qt.TabFocusReason)
        verify(checkbox.visualFocus)
        keyClick(Qt.Key_Space)
        verify(self.accepted)
        keyClick(Qt.Key_Space)
        verify(!self.accepted)
    }

    function test_disabledDoesNotActivate() {
        self.available = false
        const checkbox = createCheckbox()
        compare(checkbox.enabled, false)
        mouseClick(checkbox)
        checkbox.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Space)
        compare(toggle_spy.count, 0)
        verify(!self.accepted)
    }

    function test_tristateCycle() {
        const checkbox = createCheckbox(tristate_component)
        compare(checkbox.checkState, Qt.Unchecked)
        mouseClick(checkbox)
        compare(checkbox.checkState, Qt.PartiallyChecked)
        mouseClick(checkbox)
        compare(checkbox.checkState, Qt.Checked)
        mouseClick(checkbox)
        compare(checkbox.checkState, Qt.Unchecked)
    }

    function test_customNextCheckState() {
        const checkbox = createCheckbox(tristate_component, {
            checkState: Qt.PartiallyChecked,
            nextCheckState: () => Qt.Checked
        })
        mouseClick(checkbox)
        compare(checkbox.checkState, Qt.Checked)
    }

    Component {
        id: wrap_component
        UiCheckbox {
            width: 120
            text: "Read the full guide about recovery phrases"
            wrapMode: Text.Wrap
        }
    }

    function test_wrapUsesConstrainedWidth() {
        const checkbox = createTemporaryObject(wrap_component, self)
        verify(checkbox !== null)
        compare(checkbox.width, 120)
        verify(checkbox.height > 20)
        compare(checkbox.contentItem.wrapMode, Text.Wrap)
        compare(checkbox.contentItem.lineCount > 1, true)
    }

    function test_elideKeepsSingleLine() {
        const checkbox = createTemporaryObject(wrap_component, self, {
            wrapMode: Text.NoWrap,
            elide: Text.ElideRight
        })
        verify(checkbox !== null)
        compare(checkbox.contentItem.elide, Text.ElideRight)
        compare(checkbox.contentItem.lineCount, 1)
        verify(checkbox.contentItem.truncated)
        compare(checkbox.height, 20)
    }

    function test_labelIsPartOfControl() {
        const checkbox = createCheckbox()
        compare(checkbox.indicator.width, 20)
        compare(checkbox.contentItem.text, "Accept terms")
        compare(checkbox.height, 20)
        verify(checkbox.width > 20 + checkbox.spacing)
        const labelX = checkbox.width - 4
        mouseMove(checkbox, labelX, checkbox.height / 2)
        verify(checkbox.hovered)
        mouseClick(checkbox, labelX, checkbox.height / 2)
        verify(self.accepted)
    }

    function test_focusKeepsSize() {
        const checkbox = createCheckbox()
        const width = checkbox.width
        const height = checkbox.height
        checkbox.forceActiveFocus(Qt.TabFocusReason)
        verify(checkbox.visualFocus)
        compare(checkbox.width, width)
        compare(checkbox.height, height)
    }

    function test_accessibility_data() {
        return [
            { tag: "unchecked", state: Qt.Unchecked, checked: false, mixed: false },
            { tag: "checked", state: Qt.Checked, checked: true, mixed: false },
            { tag: "indeterminate", state: Qt.PartiallyChecked, checked: false, mixed: true }
        ]
    }

    function test_accessibility(row) {
        const checkbox = createCheckbox(tristate_component, { checkState: row.state })
        compare(checkbox.Accessible.role, Accessible.CheckBox)
        compare(checkbox.Accessible.name, "Select all")
        compare(checkbox.Accessible.checkable, true)
        compare(checkbox.Accessible.checked, row.checked)
        compare(checkbox.Accessible.checkStateMixed, row.mixed)
    }

    function test_colors_data() {
        return [
            { tag: "unchecked", state: Qt.Unchecked, disabled: false, box: "borderBold", mark: "actionOnPrimary" },
            { tag: "checked", state: Qt.Checked, disabled: false, box: "actionPrimary", mark: "actionOnPrimary" },
            { tag: "indeterminate", state: Qt.PartiallyChecked, disabled: false, box: "actionPrimary", mark: "actionOnPrimary" },
            { tag: "disabled", state: Qt.Checked, disabled: true, box: "actionDisabled", mark: "textDisabled" }
        ]
    }

    function test_colors(row) {
        const checkbox = createCheckbox(tristate_component, { checkState: row.state, disabled: row.disabled })
        compare(checkbox.boxColor, Theme.colors[row.box])
        compare(checkbox.markColor, Theme.colors[row.mark])
        checkbox.colors = Theme.lightColors
        compare(checkbox.boxColor, Theme.lightColors[row.box])
        compare(checkbox.markColor, Theme.lightColors[row.mark])
    }
}
