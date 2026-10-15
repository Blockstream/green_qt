import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtTest

GreenTestCase {
    id: self
    name: "tst_uitabs"
    when: windowShown
    width: 480
    height: 120

    property int selectedTab: 0

    Component {
        id: tabs_component
        UiTabs {
            width: 480
            UiTab { text: "Transactions" }
            UiTab { text: "Coins" }
            UiTab { text: "Addresses" }
            UiTab {
                text: "Disabled"
                disabled: true
            }
        }
    }

    Component {
        id: bound_tabs_component
        UiTabs {
            width: 480
            currentIndex: self.selectedTab
            UiTab { text: "Transactions" }
            UiTab { text: "Coins" }
            UiTab { text: "Addresses" }
            UiTab {
                text: "Disabled"
                disabled: true
            }
        }
    }

    function createTabs(properties = {}) {
        const tabs = createTemporaryObject(tabs_component, self, properties)
        verify(tabs !== null)
        return tabs
    }

    function cleanup() {
        self.selectedTab = 0
    }

    function test_defaultSelection() {
        const tabs = createTabs()
        compare(tabs.count, 4)
        compare(tabs.currentIndex, 0)
        compare(tabs.currentItem.text, "Transactions")
        verify(tabs.currentItem.checked)
    }

    function test_mouseSelection() {
        const tabs = createTabs()
        const coins = tabs.itemAt(1)
        mouseClick(coins)
        compare(tabs.currentIndex, 1)
        compare(tabs.currentItem.text, "Coins")
        verify(coins.checked)
        verify(!tabs.itemAt(0).checked)
    }

    function test_keyboardSelection() {
        const tabs = createTabs()
        tabs.itemAt(0).forceActiveFocus(Qt.TabFocusReason)
        verify(tabs.itemAt(0).visualFocus)
        keyClick(Qt.Key_Right)
        compare(tabs.currentIndex, 1)
        keyClick(Qt.Key_Left)
        compare(tabs.currentIndex, 0)
    }

    function test_disabledDoesNotActivate() {
        const tabs = createTabs()
        const disabled = tabs.itemAt(3)
        compare(disabled.enabled, false)
        mouseClick(disabled)
        compare(tabs.currentIndex, 0)
        verify(!disabled.checked)
        tabs.itemAt(0).forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Right)
        compare(tabs.currentIndex, 2)
        keyClick(Qt.Key_Right)
        // Skips the disabled tab and wraps to the first enabled one.
        compare(tabs.currentIndex, 0)
        verify(!disabled.checked)
    }

    function test_boundSelectionSurvivesDisabledSkip() {
        self.selectedTab = 0
        const tabs = createTemporaryObject(bound_tabs_component, self)
        verify(tabs !== null)
        tabs.itemAt(0).forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Right)
        compare(tabs.currentIndex, 0)
        self.selectedTab = 1
        compare(tabs.currentIndex, 1)
        compare(tabs.currentItem.text, "Coins")
    }

    function test_explicitDeselection() {
        const tabs = createTabs()
        tabs.setCurrentIndex(-1)
        compare(tabs.currentIndex, -1)
        compare(tabs.currentItem, null)
    }

    function test_removeFinalTabKeepsNoSelection() {
        const tabs = createTabs()
        while (tabs.count > 0)
            tabs.removeItem(tabs.itemAt(tabs.count - 1))
        compare(tabs.count, 0)
        compare(tabs.currentIndex, -1)
    }

    function test_focusKeepsSize() {
        const tabs = createTabs()
        const tab = tabs.itemAt(0)
        const width = tab.width
        const height = tab.height
        tab.forceActiveFocus(Qt.TabFocusReason)
        verify(tab.visualFocus)
        compare(tab.width, width)
        compare(tab.height, height)
        compare(height, 60)
    }

    function test_activeIndicatorAndColors() {
        const tabs = createTabs()
        const active = tabs.itemAt(0)
        const inactive = tabs.itemAt(1)
        compare(active.labelColor, Theme.colors.textPrimary)
        compare(inactive.labelColor, Theme.colors.textSubtle)
        compare(active.contentItem.typography, Theme.typography.labelLSemibold)
        active.colors = Theme.lightColors
        inactive.colors = Theme.lightColors
        compare(active.labelColor, Theme.lightColors.textPrimary)
        compare(inactive.labelColor, Theme.lightColors.textSubtle)
    }

    function test_longLabelElides() {
        const tabs = createTabs()
        const tab = tabs.itemAt(1)
        tab.width = 120
        tab.text = "Very long tab label that should elide"
        tab.elide = Text.ElideRight
        compare(tab.contentItem.elide, Text.ElideRight)
        compare(tab.contentItem.lineCount, 1)
        verify(tab.contentItem.truncated)
        verify(tab.width <= 120)
    }

    function test_accessibility() {
        const tabs = createTabs()
        compare(tabs.Accessible.role, Accessible.PageTabList)
        const tab = tabs.itemAt(0)
        compare(tab.Accessible.role, Accessible.PageTab)
        compare(tab.Accessible.name, "Transactions")
        compare(tab.Accessible.checked, true)
        tabs.currentIndex = 1
        compare(tabs.itemAt(0).Accessible.checked, false)
        compare(tabs.itemAt(1).Accessible.checked, true)
    }
}
