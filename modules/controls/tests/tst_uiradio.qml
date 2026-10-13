import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtQuick.Controls

GreenTestCase {
    id: self
    name: "tst_uiradio"
    when: windowShown
    width: 200
    height: 100

    property string selection: "first"

    Component {
        id: group_component
        Row {
            property alias first: first_radio
            property alias second: second_radio
            property alias third: third_radio

            spacing: 8
            UiRadio {
                id: first_radio
                text: "First"
                checked: self.selection === "first"
                onToggled: self.selection = "first"
            }
            UiRadio {
                id: second_radio
                text: "Second"
                checked: self.selection === "second"
                onToggled: self.selection = "second"
            }
            UiRadio {
                id: third_radio
                text: "Third"
                disabled: true
                checked: self.selection === "third"
                onToggled: self.selection = "third"
            }
        }
    }

    Component {
        id: button_group_component
        Column {
            property alias group: radio_group
            property alias first: first_radio
            property alias second: second_radio

            ButtonGroup {
                id: radio_group
            }
            Row {
                UiRadio {
                    id: first_radio
                    text: "First"
                    checked: true
                    ButtonGroup.group: radio_group
                }
            }
            Row {
                UiRadio {
                    id: second_radio
                    text: "Second"
                    ButtonGroup.group: radio_group
                }
            }
        }
    }

    function createGroup() {
        const group = createTemporaryObject(group_component, self)
        verify(group !== null)
        return group
    }

    function cleanup() {
        self.selection = "first"
    }

    function test_mouseSelectionIsExclusive() {
        const group = createGroup()
        verify(group.first.checked)
        mouseClick(group.second)
        compare(self.selection, "second")
        verify(group.second.checked)
        verify(!group.first.checked)
        mouseClick(group.second)
        verify(group.second.checked)
    }

    function test_buttonGroupIsExclusive() {
        const column = createTemporaryObject(button_group_component, self)
        verify(column !== null)
        compare(column.group.checkedButton, column.first)
        mouseClick(column.second)
        compare(column.group.checkedButton, column.second)
        verify(!column.first.checked)
    }

    function test_checkedFollowsBinding() {
        const group = createGroup()
        self.selection = "second"
        verify(group.second.checked)
        verify(!group.first.checked)
    }

    function test_keyboardActivation() {
        const group = createGroup()
        group.second.forceActiveFocus(Qt.TabFocusReason)
        verify(group.second.visualFocus)
        keyClick(Qt.Key_Space)
        compare(self.selection, "second")
        verify(!group.first.checked)
    }

    function test_disabledDoesNotActivate() {
        const group = createGroup()
        compare(group.third.enabled, false)
        mouseClick(group.third)
        group.third.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Space)
        compare(self.selection, "first")
        verify(!group.third.checked)
        verify(group.first.checked)
    }

    Component {
        id: wrap_component
        UiRadio {
            width: 120
            text: "Read the full guide about recovery phrases"
            wrapMode: Text.Wrap
        }
    }

    function test_wrapUsesConstrainedWidth() {
        const radio = createTemporaryObject(wrap_component, self)
        verify(radio !== null)
        compare(radio.width, 120)
        verify(radio.height > 20)
        compare(radio.contentItem.wrapMode, Text.Wrap)
        compare(radio.contentItem.lineCount > 1, true)
    }

    function test_elideKeepsSingleLine() {
        const radio = createTemporaryObject(wrap_component, self, {
            wrapMode: Text.NoWrap,
            elide: Text.ElideRight
        })
        verify(radio !== null)
        compare(radio.contentItem.elide, Text.ElideRight)
        compare(radio.contentItem.lineCount, 1)
        verify(radio.contentItem.truncated)
        compare(radio.height, 20)
    }

    function test_labelIsPartOfControl() {
        const group = createGroup()
        compare(group.first.indicator.width, 20)
        compare(group.first.contentItem.text, "First")
        compare(group.first.height, 20)
        verify(group.first.width > 20 + group.first.spacing)
        const labelX = group.second.width - 4
        mouseMove(group.second, labelX, group.second.height / 2)
        verify(group.second.hovered)
        mouseClick(group.second, labelX, group.second.height / 2)
        compare(self.selection, "second")
    }

    function test_focusKeepsSize() {
        const group = createGroup()
        const width = group.first.width
        const height = group.first.height
        group.first.forceActiveFocus(Qt.TabFocusReason)
        verify(group.first.visualFocus)
        compare(group.first.width, width)
        compare(group.first.height, height)
    }

    function test_accessibility() {
        const group = createGroup()
        compare(group.first.Accessible.role, Accessible.RadioButton)
        compare(group.first.Accessible.name, "First")
        compare(group.first.Accessible.checkable, true)
        compare(group.first.Accessible.checked, true)
        compare(group.second.Accessible.checked, false)
    }

    function test_colors() {
        const group = createGroup()
        const colors = Theme.colors
        compare(group.first.ringColor, colors.actionPrimary)
        compare(group.first.dotColor, colors.actionPrimary)
        compare(group.second.ringColor, colors.borderBold)
        compare(group.third.ringColor, colors.actionDisabled)
        group.first.colors = Theme.lightColors
        compare(group.first.ringColor, Theme.lightColors.actionPrimary)
    }
}
