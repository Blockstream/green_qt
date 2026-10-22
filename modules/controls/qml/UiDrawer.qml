import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Material as Material
import QtQuick.Controls
import QtQuick.Effects

Material.Drawer {
    property Colors colors: Theme.colors
    property string accessibleId: ''
    property real minimumContentWidth: 450
    property real preferredContentWidth: 0

    id: self
    parent: Overlay.overlay
    edge: Qt.RightEdge
    height: self.parent?.height ?? 0
    contentWidth: {
        const requestedWidth = Math.max(self.minimumContentWidth, self.preferredContentWidth)
        const availableWidth = (self.parent?.width ?? 450) - self.leftPadding - self.rightPadding
        return Math.max(0, Math.min(requestedWidth, availableWidth))
    }
    padding: 32
    topPadding: self.padding
    bottomPadding: self.padding
    leftPadding: self.padding
    rightPadding: self.padding
    z: 2
    focus: true
    modal: true
    dim: true
    interactive: self.visible
    clip: true
    closePolicy: Material.Popup.CloseOnEscape | Material.Popup.CloseOnPressOutside

    Behavior on contentWidth {
        SmoothedAnimation { velocity: 500 }
    }
    Overlay.modal: MultiEffect {
        anchors.fill: parent
        source: self.ApplicationWindow.contentItem
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: self.position
    }
    PopupAccessibility {
        popup: self
        accessibleId: self.accessibleId
    }
    background: Rectangle {
        color: self.colors.surfaceOverlay
    }
}
