import Blockstream.Controls
import Blockstream.Testing
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uipopup'
    when: windowShown
    width: 720
    height: 560

    Component {
        id: host_component
        Item {
            property alias trigger: trigger_button
            property alias popup: example_popup
            property int openings: 0

            id: host
            width: self.width
            height: self.height
            UiButton {
                id: trigger_button
                x: 240
                y: 20
                text: 'Open popup'
                onClicked: example_popup.open()
                UiPopup {
                    id: example_popup
                    accessibleId: 'test_popup'
                    width: 240
                    y: trigger_button.height + 8
                    onAboutToShow: host.openings++
                    contentItem: Item {
                        implicitHeight: 80
                    }
                }
            }
        }
    }
    Component {
        id: popup_component
        UiPopup {
            width: 240
            height: 120
        }
    }
    Component {
        id: content_component
        Item {
            implicitWidth: 200
            implicitHeight: 80
        }
    }

    function createHost() {
        const host = createTemporaryObject(host_component, self)
        verify(host !== null)
        return host
    }

    function openPopup(host) {
        mouseClick(host.trigger)
        tryCompare(host.popup, 'opened', true)
    }

    function test_defaultContentRootGetsAndUpdatesAccessibleId() {
        const popup = createTemporaryObject(popup_component, self, { accessibleId: 'first_popup' })
        verify(popup !== null)
        tryCompare(popup.contentItem.Accessible, 'id', 'first_popup')
        popup.accessibleId = 'second_popup'
        tryCompare(popup.contentItem.Accessible, 'id', 'second_popup')
        popup.accessibleId = ''
        tryCompare(popup.contentItem.Accessible, 'id', '')
    }

    function test_callerOwnedAndReplacedContentGetAccessibleId() {
        const host = createHost()
        tryCompare(host.popup.contentItem.Accessible, 'id', 'test_popup')
        const replacement = createTemporaryObject(content_component, host)
        verify(replacement !== null)
        replacement.Accessible.role = Accessible.Pane
        host.popup.contentItem = replacement
        tryCompare(replacement.Accessible, 'id', 'test_popup')
        compare(replacement.Accessible.role, Accessible.Grouping)
        host.popup.accessibleId = 'replaced_popup'
        tryCompare(replacement.Accessible, 'id', 'replaced_popup')
        host.popup.accessibleId = ''
        tryCompare(replacement.Accessible, 'role', Accessible.Pane)
    }

    function test_escapeDismisses() {
        const host = createHost()
        openPopup(host)
        host.popup.contentItem.forceActiveFocus()
        keyClick(Qt.Key_Escape)
        tryCompare(host.popup, 'visible', false)
    }

    function test_outsideClickDismisses() {
        const host = createHost()
        openPopup(host)
        mouseClick(host, host.width - 10, host.height - 10)
        tryCompare(host.popup, 'visible', false)
    }

    function test_triggerClickDismissesWithoutReopening() {
        const host = createHost()
        openPopup(host)
        compare(host.openings, 1)
        mouseClick(host.trigger)
        tryCompare(host.popup, 'visible', false)
        compare(host.openings, 1)
        mouseClick(host.trigger)
        tryCompare(host.popup, 'opened', true)
        compare(host.openings, 2)
        host.popup.close()
    }
}
