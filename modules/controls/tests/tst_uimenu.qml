import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtQml.Models

GreenTestCase {
    id: self
    name: 'tst_uimenu'
    when: windowShown
    width: 720
    height: 560

    Component {
        id: host_component
        Item {
            property alias trigger: trigger_button
            property alias menu: popup_menu
            property int openings: 0
            property int activations: 0
            property int extraCount: 0

            id: host
            width: self.width
            height: self.height
            UiButton {
                id: trigger_button
                x: 240
                y: 20
                text: 'Options'
                onClicked: if (!popup_menu.visible) popup_menu.open()
                UiMenu {
                    id: popup_menu
                    accessibleId: 'test_menu'
                    x: (trigger_button.width - width) / 2
                    y: trigger_button.height + 8
                    onAboutToShow: host.openings++
                    UiMenuItem {
                        text: 'View archived accounts'
                        count: 2
                        iconName: Theme.icons.archive
                        onTriggered: host.activations++
                    }
                    UiMenuItem {
                        text: 'Unavailable'
                        enabled: false
                        onTriggered: host.activations++
                    }
                    UiMenuSeparator {}
                    UiMenuItem {
                        text: 'Refresh'
                        iconName: Theme.icons.arrowsClockwise
                        onTriggered: host.activations++
                    }
                    Instantiator {
                        model: host.extraCount
                        onObjectAdded: (index, object) => popup_menu.insertItem(index + 4, object)
                        onObjectRemoved: (index, object) => popup_menu.removeItem(object)
                        delegate: UiMenuItem {
                            required property int index
                            text: `Action ${index + 1}`
                            iconName: Theme.icons.wallet
                        }
                    }
                }
            }
        }
    }

    Component {
        id: content_component
        Item {
            implicitWidth: 240
            implicitHeight: 120
        }
    }

    Component {
        id: caller_content_menu
        UiMenu {
            accessibleId: 'caller_menu'
            contentItem: Rectangle {
                implicitWidth: 240
                implicitHeight: 120
                Accessible.role: Accessible.StaticText
                Accessible.name: 'Caller supplied content'
            }
        }
    }

    function createHost() {
        const host = createTemporaryObject(host_component, self)
        verify(host !== null)
        return host
    }

    function openMenu(host) {
        mouseClick(host.trigger)
        tryCompare(host.menu, 'opened', true)
        verify(host.menu.width > 0)
    }

    function test_contentDrivenSizeAndCompactSeparator() {
        const host = createHost()
        openMenu(host)
        const menu = host.menu
        verify(menu.width > 200)
        verify(menu.width <= 360)
        verify(menu.height < 300)
        const label = self.findItems(menu.itemAt(0).contentItem, child => child instanceof UiLabel)[0]
        verify(!label.truncated)
        compare(menu.itemAt(2).height, 1)
        verify(menu.itemAt(0).width >= menu.itemAt(0).implicitWidth)
        verify(menu.itemAt(3).y + menu.itemAt(3).height <= menu.contentItem.height)
        compare(menu.contentItem.Accessible.id, 'test_menu')
        menu.close()
    }

    function test_callerSuppliedContentRootOnFirstOpen() {
        const menu = createTemporaryObject(caller_content_menu, self)
        verify(menu !== null)
        tryCompare(menu.contentItem.Accessible, 'id', 'caller_menu')
        compare(menu.contentItem.Accessible.role, Qt.platform.os === 'osx' ? Accessible.Grouping : Accessible.PopupMenu)
        menu.open()
        tryCompare(menu, 'opened', true)
        compare(menu.contentItem.Accessible.id, 'caller_menu')
        compare(menu.contentItem.Accessible.role, Qt.platform.os === 'osx' ? Accessible.Grouping : Accessible.PopupMenu)
        menu.close()
    }

    function test_replacedContentRootGetsAndUpdatesAccessibleId() {
        const host = createHost()
        const replacement = createTemporaryObject(content_component, host)
        verify(replacement !== null)
        replacement.Accessible.role = Accessible.Pane
        host.menu.contentItem = replacement
        tryCompare(replacement.Accessible, 'id', 'test_menu')
        compare(replacement.Accessible.role, Qt.platform.os === 'osx' ? Accessible.Grouping : Accessible.PopupMenu)
        host.menu.accessibleId = 'replacement_menu'
        tryCompare(replacement.Accessible, 'id', 'replacement_menu')
        host.menu.accessibleId = ''
        tryCompare(replacement.Accessible, 'id', '')
        compare(replacement.Accessible.role, Accessible.Pane)
    }

    function test_countUpdatesAndParenthesesAreLiteral() {
        const host = createHost()
        openMenu(host)
        const menu = host.menu
        const item = menu.itemAt(0)
        const labels = self.findItems(item.contentItem, child => child instanceof UiLabel)
        compare(labels.length, 2)
        item.text = 'Archive (local wallet)'
        compare(labels[0].text, item.text)
        compare(labels[1].text, '2')
        compare(item.Accessible.name, 'Archive (local wallet) (2)')
        item.count = 120
        compare(labels[1].text, '120')
        compare(item.Accessible.name, 'Archive (local wallet) (120)')
        const width_with_badge = menu.width
        item.count = 0
        compare(labels[1].visible, false)
        compare(item.Accessible.name, item.text)
        tryVerify(() => menu.width < width_with_badge)
        menu.close()
    }

    function test_longLabelsStayOnOneLineAndWidthIsCapped() {
        const host = createHost()
        const item = host.menu.itemAt(0)
        const original_height = item.implicitHeight
        item.text = 'A very long menu label that must elide instead of wrapping and hiding the remaining menu actions'
        openMenu(host)
        compare(host.menu.width, 360)
        compare(item.height, original_height)
        const label = self.findItems(item.contentItem, child => child instanceof UiLabel)[0]
        tryCompare(label, 'truncated', true)
        host.menu.close()
    }

    function test_reopeningUsesUpdatedContentSize() {
        const host = createHost()
        openMenu(host)
        const original_width = host.menu.width
        host.menu.close()
        tryCompare(host.menu, 'visible', false)
        const item = host.menu.itemAt(0)
        const original_text = item.text
        item.text = 'A long label changed while the menu is closed must be sized before it opens again'
        item.count = 120
        openMenu(host)
        compare(host.menu.width, 360)
        host.menu.close()
        tryCompare(host.menu, 'visible', false)
        item.text = original_text
        item.count = 2
        openMenu(host)
        compare(host.menu.width, original_width)
        host.menu.close()
    }

    function test_tallMenuScrollsToLastAction() {
        const host = createHost()
        host.extraCount = 16
        tryCompare(host.menu, 'count', 20)
        openMenu(host)
        const menu = host.menu
        compare(menu.height, 300)
        tryVerify(() => menu.contentItem.contentHeight > menu.contentItem.height)
        verify(menu.contentItem.interactive)
        menu.contentItem.positionViewAtIndex(menu.count - 1, ListView.End)
        tryVerify(() => menu.contentItem.contentY > 0)
        const last_item = menu.itemAt(menu.count - 1)
        const position = last_item.mapToItem(menu.contentItem, 0, 0)
        verify(position.y >= -1)
        verify(position.y + last_item.height <= menu.contentItem.height + 1)
        menu.close()
    }

    function test_keyboardSkipsDisabledAndSeparatorAndActivates() {
        const host = createHost()
        openMenu(host)
        host.menu.itemAt(0).forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Down)
        tryCompare(host.menu, 'currentIndex', 3)
        keyClick(Qt.Key_Return)
        compare(host.activations, 1)
        tryCompare(host.menu, 'visible', false)
    }

    function test_disabledActionDoesNotActivate() {
        const host = createHost()
        openMenu(host)
        mouseClick(host.menu.itemAt(1))
        compare(host.activations, 0)
        verify(host.menu.visible)
        host.menu.close()
    }

    function test_escapeDismisses() {
        const host = createHost()
        openMenu(host)
        host.menu.itemAt(0).forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Escape)
        tryCompare(host.menu, 'visible', false)
        compare(host.activations, 0)
    }

    function test_outsideClickDismisses() {
        const host = createHost()
        openMenu(host)
        mouseClick(host, host.width - 10, host.height - 10)
        tryCompare(host.menu, 'visible', false)
        compare(host.activations, 0)
    }

    function test_triggerClickDismissesWithoutReopening() {
        const host = createHost()
        openMenu(host)
        compare(host.openings, 1)
        mouseClick(host.trigger)
        tryCompare(host.menu, 'visible', false)
        compare(host.openings, 1)
        mouseClick(host.trigger)
        tryCompare(host.menu, 'opened', true)
        compare(host.openings, 2)
        host.menu.close()
    }
    Component {
        id: menu_component
        UiMenuItem {
            text: 'Sort'
            checkable: true
        }
    }
    function test_checkableSelection() {
        const item = createTemporaryObject(menu_component, self)
        mouseClick(item)
        compare(item.checked, true)
        mouseClick(item)
        compare(item.checked, false)
        item.enabled = false
        mouseClick(item)
        compare(item.checked, false)
    }

}
