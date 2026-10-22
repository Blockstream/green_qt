import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Controls
import QtQuick.Effects

Basic.Menu {
    property Colors colors: Theme.colors
    property real pointerX: 0.5
    property real pointerY: 0
    property string accessibleId: ''

    id: self
    modal: true
    dim: false
    closePolicy: Basic.Popup.CloseOnEscape | Basic.Popup.CloseOnPressOutside
    padding: 1
    spacing: 0
    font: Theme.typography.bodyM.font
    implicitWidth: Math.min(360, Math.max(200, (self.contentItem?.implicitWidth ?? 0) + leftPadding + rightPadding))
    implicitHeight: Math.min(300, (self.contentItem?.implicitHeight ?? 0) + topPadding + bottomPadding)
    onAboutToShow: {
        // Closed menus do not receive a polish pass before their first frame.
        for (let index = 0; index < self.count; ++index) {
            const item = self.itemAt(index)
            item?.contentItem?.ensurePolished()
            item?.ensurePolished()
        }
        if (self.contentItem === menu_content) menu_content.forceLayout()
    }
    contentItem: ListView {
        readonly property var menuItems: Array.from({ length: self.count }, (_, index) => self.itemAt(index))

        id: menu_content
        Accessible.role: Accessible.PopupMenu
        implicitWidth: menu_content.menuItems.reduce((width, item) => Math.max(width, item?.implicitWidth ?? 0), 0)
        implicitHeight: menu_content.menuItems.reduce((height, item) => height + (item?.implicitHeight ?? 0), 0)
        contentHeight: implicitHeight
        cacheBuffer: implicitHeight
        model: self.contentModel
        currentIndex: self.currentIndex
        clip: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: content_mask
        }
        Rectangle {
            id: content_mask
            parent: menu_content
            width: menu_content.width
            height: menu_content.height
            radius: Math.max(0, self.background.radius - self.padding)
            color: 'white'
            visible: false
            layer.enabled: true
        }
        keyNavigationWraps: true
        interactive: contentHeight > height
        ScrollIndicator.vertical: ScrollIndicator {}
    }
    PopupAccessibility {
        popup: self
        accessibleId: self.accessibleId
        role: Accessible.PopupMenu
    }
    background: UiPopupSurface {
        colors: self.colors
        pointerX: self.pointerX
        pointerY: self.pointerY
    }
}
