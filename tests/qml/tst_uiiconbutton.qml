import Blockstream.Controls
import Blockstream.Theme
import QtQuick

GreenTestCase {
    id: self
    name: "tst_uiiconbutton"
    when: windowShown
    width: 240
    height: 160

    Component {
        id: button_component
        UiIconButton {
            text: "Copy address"
            iconName: Theme.icons.copy
        }
    }

    function createButton(properties = {}) {
        const button = createTemporaryObject(button_component, self, properties)
        verify(button !== null)
        return button
    }

    function test_defaultsAndContent() {
        const button = createButton({ trailingIconName: Theme.icons.check })
        compare(button.variant, UiButton.Tertiary)
        compare(button.size, UiButton.Medium)
        compare(button.Accessible.name, "Copy address")
        const icons = self.findItems(button.contentItem, item => item instanceof UiIcon)
        compare(icons.length, 1)
        compare(icons[0].name, Theme.icons.copy)
        compare(icons[0].Accessible.ignored, true)
        compare(self.findItems(button.contentItem, item => item instanceof UiLabel).length, 0)
        button.text = "A much longer accessible name for the same icon-only action"
        compare(button.Accessible.name, button.text)
        compare(button.width, 40)
    }

    function test_geometry_data() {
        return [
            { tag: "large", size: UiButton.Large, side: 56, icon: 24, padding: 16 },
            { tag: "medium", size: UiButton.Medium, side: 40, icon: 24, padding: 8 },
            { tag: "small", size: UiButton.Small, side: 36, icon: 20, padding: 8 },
            { tag: "extra small", size: UiButton.ExtraSmall, side: 28, icon: 16, padding: 6 }
        ]
    }

    function test_geometry(row) {
        const button = createButton({ size: row.size })
        const icon = self.findItems(button.contentItem, item => item instanceof UiIcon)[0]
        compare(button.width, row.side)
        compare(button.height, row.side)
        compare(icon.width, row.icon)
        compare(icon.height, row.icon)
        const position = icon.mapToItem(button, 0, 0)
        compare(position.x, row.padding)
        compare(position.y, row.padding)
        button.forceActiveFocus(Qt.TabFocusReason)
        verify(button.visualFocus)
        compare(button.width, row.side)
        compare(button.height, row.side)
        button.busy = true
        compare(button.width, row.side)
        compare(button.height, row.side)
        compare(icon.opacity, 0)
        const spinner = self.findItems(button.contentItem, item => item instanceof UiSpinner)[0]
        compare(spinner.running, true)
        compare(spinner.width, row.icon)
        compare(spinner.height, row.icon)
        const spinnerPosition = spinner.mapToItem(button, 0, 0)
        compare(spinnerPosition.x, row.padding)
        compare(spinnerPosition.y, row.padding)
        button.busy = false
        compare(icon.opacity, 1)
    }
}
