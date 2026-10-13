import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtTest

GreenTestCase {
    id: self
    name: "tst_uitoggle"
    when: windowShown
    width: 200
    height: 100

    property bool enabledSetting: false
    property bool available: true

    Component {
        id: toggle_component
        UiToggle {
            text: "Notifications"
            disabled: !self.available
            checked: self.enabledSetting
            onToggled: self.enabledSetting = checked
        }
    }

    SignalSpy {
        id: toggle_spy
        signalName: "toggled"
    }

    function createToggle(properties = {}) {
        const toggle = createTemporaryObject(toggle_component, self, properties)
        verify(toggle !== null)
        toggle_spy.target = toggle
        toggle_spy.clear()
        return toggle
    }

    function cleanup() {
        toggle_spy.target = null
        self.enabledSetting = false
        self.available = true
    }

    function test_mouseToggle() {
        const toggle = createToggle()
        mouseClick(toggle)
        verify(self.enabledSetting)
        verify(toggle.checked)
        mouseClick(toggle)
        verify(!self.enabledSetting)
        verify(!toggle.checked)
        compare(toggle_spy.count, 2)
    }

    function test_checkedFollowsBinding() {
        const toggle = createToggle()
        self.enabledSetting = true
        verify(toggle.checked)
        self.enabledSetting = false
        verify(!toggle.checked)
    }

    function test_keyboardActivation() {
        const toggle = createToggle()
        toggle.forceActiveFocus(Qt.TabFocusReason)
        verify(toggle.visualFocus)
        keyClick(Qt.Key_Space)
        verify(self.enabledSetting)
        keyClick(Qt.Key_Space)
        verify(!self.enabledSetting)
        compare(toggle_spy.count, 2)
    }

    function test_disabledDoesNotActivate() {
        self.available = false
        const toggle = createToggle()
        compare(toggle.enabled, false)
        mouseClick(toggle)
        toggle.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Space)
        compare(toggle_spy.count, 0)
        verify(!self.enabledSetting)
    }

    Component {
        id: wrap_component
        UiToggle {
            width: 200
            text: "Read the full guide about recovery phrases"
            wrapMode: Text.Wrap
        }
    }

    function test_wrapUsesConstrainedWidth() {
        const toggle = createTemporaryObject(wrap_component, self)
        verify(toggle !== null)
        compare(toggle.width, 200)
        compare(toggle.contentItem.wrapMode, Text.Wrap)
        compare(toggle.contentItem.lineCount > 1, true)
        verify(toggle.height > 28)
        verify(toggle.height >= toggle.contentItem.implicitHeight)
    }

    function test_elideKeepsSingleLine() {
        const toggle = createTemporaryObject(wrap_component, self, {
            wrapMode: Text.NoWrap,
            elide: Text.ElideRight
        })
        verify(toggle !== null)
        compare(toggle.contentItem.elide, Text.ElideRight)
        compare(toggle.contentItem.lineCount, 1)
        verify(toggle.contentItem.truncated)
        compare(toggle.height, 28)
    }

    function test_labelIsPartOfControl() {
        const toggle = createToggle()
        compare(toggle.indicator.width, 48)
        compare(toggle.height, 28)
        compare(toggle.contentItem.text, "Notifications")
        compare(toggle.indicator.x, toggle.width - 48)
        mouseMove(toggle, 4, toggle.height / 2)
        verify(toggle.hovered)
        mouseClick(toggle, 4, toggle.height / 2)
        verify(self.enabledSetting)
    }

    function test_knobAnimates() {
        const toggle = createToggle()
        // indicator children: focus ring, track, knob
        const knob = toggle.indicator.children[2]
        compare(knob.x, 3)
        compare(knob.width, 22)
        toggle.toggle()
        verify(knob.x < toggle.indicator.width - knob.width - 3)
        tryCompare(knob, "x", toggle.indicator.width - knob.width - 3)
    }

    function test_focusKeepsSize() {
        const toggle = createToggle()
        const width = toggle.width
        const height = toggle.height
        toggle.forceActiveFocus(Qt.TabFocusReason)
        verify(toggle.focusRingVisible)
        compare(toggle.width, width)
        compare(toggle.height, height)
    }

    function test_focusedKnobFitsTrack() {
        const toggle = createToggle()
        const knob = toggle.indicator.children[2]
        toggle.forceActiveFocus(Qt.TabFocusReason)
        verify(toggle.focusRingVisible)
        compare(knob.width, 14)
        compare(knob.height, 14)
        compare(knob.y, 7)
        // Behavior on x also runs when the focused track inset changes.
        tryCompare(knob, "x", 7)
        toggle.toggle()
        tryCompare(knob, "x", 7 + (40 - 14 - 6))
        compare(knob.y, 7)
        compare(knob.width, 14)
    }

    function test_accessibility() {
        const toggle = createToggle()
        compare(toggle.Accessible.role, Accessible.Switch)
        compare(toggle.Accessible.name, "Notifications")
        compare(toggle.Accessible.checkable, true)
        compare(toggle.Accessible.checked, false)
        self.enabledSetting = true
        compare(toggle.Accessible.checked, true)
    }

    function test_colors_data() {
        return [
            { tag: "off", checked: false, disabled: false, track: "surfaceRaised", knob: "iconBase" },
            { tag: "on", checked: true, disabled: false, track: "actionPrimary", knob: "iconBase" },
            { tag: "disabled off", checked: false, disabled: true, track: "actionDisabled", knob: "textDisabled" },
            { tag: "disabled on", checked: true, disabled: true, track: "actionDisabled", knob: "textDisabled" }
        ]
    }

    function test_colors(row) {
        self.enabledSetting = row.checked
        self.available = !row.disabled
        const toggle = createToggle()
        compare(toggle.trackColor, Theme.colors[row.track])
        compare(toggle.knobColor, Theme.colors[row.knob])
        toggle.colors = Theme.lightColors
        compare(toggle.trackColor, Theme.lightColors[row.track])
        compare(toggle.knobColor, Theme.lightColors[row.knob])
    }
}
