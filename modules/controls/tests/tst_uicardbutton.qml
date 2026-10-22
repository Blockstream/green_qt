import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtTest

GreenTestCase {
    id: self
    name: 'tst_uicardbutton'
    when: windowShown
    width: 480
    height: 240

    Component {
        id: card_component
        UiCardButton {
            x: 20
            y: 20
            width: 320
            height: 72
            text: 'Open wallet'
            contentItem: UiLabel {
                text: parent.text
                typography: Theme.typography.labelLMedium
            }
        }
    }
    SignalSpy { id: click_spy; signalName: 'clicked' }

    function createCard(properties = {}) {
        const card = createTemporaryObject(card_component, self, properties)
        verify(card !== null)
        click_spy.target = card
        click_spy.clear()
        return card
    }

    function cleanup() {
        click_spy.target = null
        mouseMove(self, self.width - 1, self.height - 1)
    }

    function test_mouseAndKeyboardActivation() {
        const card = createCard()
        mouseClick(card)
        compare(click_spy.count, 1)
        card.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Space)
        compare(click_spy.count, 2)
    }

    function test_disabledSuppressesActivationAndCanReenable() {
        const card = createCard({ disabled: true })
        mouseClick(card)
        card.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Space)
        compare(click_spy.count, 0)
        card.disabled = false
        mouseClick(card)
        compare(click_spy.count, 1)
    }

    function test_disablingDuringPressCancelsActivation() {
        const card = createCard()
        mousePress(card)
        card.disabled = true
        mouseRelease(card)
        compare(click_spy.count, 0)
    }

    function test_hoverPressAndFocusPreserveGeometry() {
        const card = createCard()
        const content = card.contentItem
        const geometry = [card.width, card.height, content.x, content.y, content.width, content.height]
        mouseMove(card)
        tryCompare(card, 'hovered', true)
        compare(card.background.color, card.colors.surfaceHover)
        mousePress(card)
        compare(card.background.color, card.colors.surfaceSunken)
        mouseRelease(card)
        self.forceActiveFocus()
        verify(!card.activeFocus)
        card.forceActiveFocus(Qt.TabFocusReason)
        verify(card.visualFocus)
        compare([card.width, card.height, content.x, content.y, content.width, content.height], geometry)
        compare(card.Accessible.name, 'Open wallet')
    }
}
