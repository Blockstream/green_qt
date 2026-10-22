import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Material as Material
import QtQuick.Controls
import QtQuick.Effects

Material.Dialog {
    property Colors colors: Theme.colors
    property string accessibleId: ''

    id: self
    parent: Overlay.overlay
    anchors.centerIn: parent
    implicitWidth: 400
    width: Math.min(implicitWidth, Math.max(0, (parent?.width ?? implicitWidth) - 2 * margins))
    margins: 24
    padding: 32
    topPadding: self.padding
    bottomPadding: self.padding
    leftPadding: self.padding
    rightPadding: self.padding
    spacing: 20
    z: 2
    focus: true
    modal: true
    dim: true
    closePolicy: Material.Popup.CloseOnEscape | Material.Popup.CloseOnPressOutside
    header: null
    footer: null

    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.visible ? -0.05 : 0
        Behavior on brightness {
            NumberAnimation { duration: 200 }
        }
        blurEnabled: true
        blurMax: 64
        blur: self.visible ? 1 : 0
        Behavior on blur {
            NumberAnimation { duration: 200 }
        }
        source: self.ApplicationWindow.contentItem
    }

    PopupAccessibility {
        popup: self
        accessibleId: self.accessibleId
        role: Accessible.Dialog
    }
    background: Rectangle {
        color: self.colors.surfaceOverlay
        radius: 12
    }
}
