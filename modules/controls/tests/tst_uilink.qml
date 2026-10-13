import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtTest

GreenTestCase {
    id: self
    name: "tst_uilink"
    when: windowShown
    width: 300
    height: 100

    Component {
        id: link_component
        UiLink {
            text: "Learn more"
            url: "https://blockstream.com"
        }
    }

    SignalSpy {
        id: activated_spy
        signalName: "linkActivated"
    }

    function createLink(properties = {}) {
        const link = createTemporaryObject(link_component, self, properties)
        verify(link !== null)
        activated_spy.target = link
        activated_spy.clear()
        return link
    }

    function cleanup() {
        activated_spy.target = null
    }

    function test_mouseActivation() {
        const link = createLink()
        mouseClick(link)
        compare(activated_spy.count, 1)
        compare(activated_spy.signalArguments[0][0], link.url)
    }

    function test_keyboardActivation() {
        const link = createLink()
        link.forceActiveFocus(Qt.TabFocusReason)
        verify(link.visualFocus)
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        keyClick(Qt.Key_Enter)
        compare(activated_spy.count, 3)
    }

    function test_disabledDoesNotActivate() {
        const link = createLink({ disabled: true })
        compare(link.enabled, false)
        mouseClick(link)
        link.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Return)
        compare(activated_spy.count, 0)
    }

    function test_emptyUrlDoesNotActivate() {
        const link = createLink({ url: "" })
        verify(!link.activatable)
        mouseClick(link)
        link.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Return)
        compare(activated_spy.count, 0)
    }

    function test_hover() {
        const link = createLink()
        mouseMove(link)
        verify(link.interactionHovered)
        compare(link.foregroundColor, Theme.colors.textBrandHover)
        compare(link.iconColor, Theme.colors.textBrandHover)
    }

    function test_emptyUrlHasNoHover() {
        const link = createLink({ url: "" })
        mouseMove(link)
        verify(link.hovered)
        verify(!link.interactionHovered)
        compare(link.foregroundColor, Theme.colors.textBrand)
        compare(link.iconColor, Theme.colors.iconBrand)
    }

    function test_colors_data() {
        return [
            { tag: "enabled", disabled: false, text: "textBrand", icon: "iconBrand" },
            { tag: "disabled", disabled: true, text: "textDisabled", icon: "iconDisabled" }
        ]
    }

    function test_colors(row) {
        const link = createLink({ disabled: row.disabled })
        compare(link.foregroundColor, Theme.colors[row.text])
        compare(link.iconColor, Theme.colors[row.icon])
        link.colors = Theme.lightColors
        compare(link.foregroundColor, Theme.lightColors[row.text])
        compare(link.iconColor, Theme.lightColors[row.icon])
    }

    function test_focusKeepsSize() {
        const link = createLink()
        const width = link.width
        const height = link.height
        link.forceActiveFocus(Qt.TabFocusReason)
        verify(link.visualFocus)
        compare(link.width, width)
        compare(link.height, height)
    }

    function test_accessibility() {
        const link = createLink()
        compare(link.Accessible.role, Accessible.Link)
        compare(link.Accessible.name, "Learn more")
    }
}
