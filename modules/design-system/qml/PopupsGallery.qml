import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Layouts
import QtQml.Models

ColumnLayout {
    required property Colors colors
    property int archivedCount: 2
    property string lastAction: 'No action selected'

    id: self
    Layout.minimumWidth: 0
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.Wrap
            text: 'UiMenu / UiMenuItem / UiMenuSeparator'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'Try mouse and keyboard selection, Escape, and clicking outside or on the trigger to dismiss. Long labels elide; tall menus scroll.'
            typography: Theme.typography.bodyS
            color: self.colors.textSubtle
            wrapMode: Text.Wrap
        }
    }
    Flow {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 12
        UiButton {
            text: 'Open menu'
            variant: UiButton.Secondary
            colors: self.colors
            onClicked: if (!example_menu.visible) example_menu.open()
            UiMenu {
                id: example_menu
                colors: self.colors
                accessibleId: 'gallery_example_menu'
                width: Math.min(implicitWidth, self.width)
                x: Math.max(-parent.x, Math.min(0, self.width - parent.x - width))
                pointerX: Math.max(0.05, Math.min(0.95, (parent.width / 2 - x) / width))
                y: parent.height + 8
                UiMenuItem {
                    colors: self.colors
                    text: 'Rename (local wallet)'
                    iconName: Theme.icons.textAa
                    onTriggered: self.lastAction = text
                }
                UiMenuItem {
                    colors: self.colors
                    text: 'View archived accounts'
                    count: self.archivedCount
                    iconName: Theme.icons.archive
                    enabled: count > 0
                    onTriggered: self.lastAction = `${text}: ${count}`
                }
                UiMenuItem {
                    text: 'Selected sorting option'
                    colors: self.colors
                    checkable: true
                    checked: true
                }
                UiMenuSeparator { colors: self.colors }
                UiMenuItem {
                    colors: self.colors
                    text: 'Unavailable action'
                    iconName: Theme.icons.plusCircle
                    enabled: false
                }
                UiMenuItem {
                    colors: self.colors
                    text: 'A deliberately long menu label that exceeds the maximum menu width'
                    iconName: Theme.icons.supportRegular
                    onTriggered: self.lastAction = text
                }
            }
        }
        UiButton {
            text: 'Scrollable menu'
            variant: UiButton.Secondary
            colors: self.colors
            onClicked: if (!scroll_menu.visible) scroll_menu.open()
            UiMenu {
                id: scroll_menu
                colors: self.colors
                accessibleId: 'gallery_scroll_menu'
                width: Math.min(implicitWidth, self.width)
                x: Math.max(-parent.x, Math.min(0, self.width - parent.x - width))
                pointerX: Math.max(0.05, Math.min(0.95, (parent.width / 2 - x) / width))
                y: parent.height + 8
                Instantiator {
                    model: 16
                    onObjectAdded: (index, object) => scroll_menu.insertItem(index, object)
                    onObjectRemoved: (index, object) => scroll_menu.removeItem(object)
                    delegate: UiMenuItem {
                        required property int index
                        colors: self.colors
                        text: `Action ${index + 1}`
                        iconName: Theme.icons.wallet
                        enabled: index !== 3
                        onTriggered: self.lastAction = text
                    }
                }
            }
        }
        UiButton {
            text: 'Change count'
            variant: UiButton.Tertiary
            colors: self.colors
            onClicked: self.archivedCount = self.archivedCount === 20 ? 0 : self.archivedCount + 1
        }
    }
    UiLabel {
        text: `Archive count: ${self.archivedCount} · ${self.lastAction}`
        typography: Theme.typography.bodyS
        color: self.colors.textSubtle
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
    UiLabel {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        wrapMode: Text.Wrap
        text: 'UiPopup / UiPopupSurface'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    UiButton {
        text: 'Open popup'
        variant: UiButton.Secondary
        colors: self.colors
        onClicked: example_popup.open()
        UiPopup {
            id: example_popup
            colors: self.colors
            accessibleId: 'gallery_example_popup'
            width: Math.min(280, self.width)
            x: 0
            pointerX: Math.min(0.95, parent.width / (2 * width))
            y: parent.height + 8
            contentItem: ColumnLayout {
                spacing: 12
                UiLabel {
                    Layout.fillWidth: true
                    text: 'Caller-owned content on the shared popup surface.'
                    typography: Theme.typography.bodyM
                    color: self.colors.textPrimary
                    wrapMode: Text.Wrap
                }
                UiButton {
                    text: 'Close'
                    size: UiButton.Small
                    colors: self.colors
                    onClicked: example_popup.close()
                }
            }
        }
    }
}
