import Blockstream.Controls
import QtQuick
import QtTest

GreenTestCase {
    id: self
    name: "tst_uibutton"
    when: windowShown
    width: 200
    height: 100

    property bool canSubmit: true

    Component {
        id: button_component
        UiButton {
            text: "Continue"
            disabled: !self.canSubmit
        }
    }

    SignalSpy {
        id: click_spy
        signalName: "clicked"
    }

    function createButton(properties = {}) {
        const button = createTemporaryObject(button_component, self, properties)
        verify(button !== null)
        click_spy.target = button
        click_spy.clear()
        return button
    }

    function cleanup() {
        click_spy.target = null
        self.canSubmit = true
    }

    function test_activation_data() {
        return [
            { tag: "available", disabled: false, busy: false, clicks: 2 },
            { tag: "disabled", disabled: true, busy: false, clicks: 0 },
            { tag: "busy", disabled: false, busy: true, clicks: 0 },
            { tag: "disabled and busy", disabled: true, busy: true, clicks: 0 }
        ]
    }

    function test_activation(row) {
        self.canSubmit = !row.disabled
        const button = createButton({ busy: row.busy })
        compare(button.enabled, !row.disabled && !row.busy)
        mouseClick(button)
        button.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Space)
        if (row.disabled || row.busy) {
            keyClick(Qt.Key_Return)
            keyClick(Qt.Key_Enter)
        }
        compare(click_spy.count, row.clicks)
    }

    function test_loadingPreservesCallerAvailability() {
        const button = createButton()
        button.busy = true
        compare(button.enabled, false)
        self.canSubmit = false
        button.busy = false
        compare(button.disabled, true)
        compare(button.enabled, false)
        self.canSubmit = true
        compare(button.enabled, true)
        mouseClick(button)
        compare(click_spy.count, 1)
    }

    function test_loadingCancelsPress() {
        const button = createButton()
        mousePress(button)
        verify(button.down)
        button.busy = true
        mouseRelease(button)
        compare(click_spy.count, 0)
        button.busy = false
        mouseClick(button)
        compare(click_spy.count, 1)
    }
}
