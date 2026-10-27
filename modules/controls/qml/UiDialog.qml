import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Material as Material
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Material.Dialog {
    property Colors colors: Theme.colors
    property string accessibleId: ''
    property bool dismissible: true

    readonly property bool canDismiss: self.dismissible && self.closePolicy !== Material.Popup.NoAutoClose

    id: self
    parent: Overlay.overlay
    anchors.centerIn: parent
    implicitWidth: 400
    width: Math.min(implicitWidth, Math.max(0, (parent?.width ?? implicitWidth) - 2 * margins))
    margins: 24
    padding: 32
    // The default header carries the top inset; leave only section spacing below it.
    topPadding: self.header === dialog_header && dialog_header.visible ? 0 : self.padding
    bottomPadding: self.padding
    leftPadding: self.padding
    rightPadding: self.padding
    spacing: 20
    z: 2
    focus: true
    modal: true
    dim: true
    closePolicy: self.dismissible ? Material.Popup.CloseOnEscape | Material.Popup.CloseOnPressOutside : Material.Popup.NoAutoClose
    header: Pane {
        id: dialog_header
        visible: self.title.length > 0 || self.canDismiss
        padding: 0
        topPadding: self.padding
        leftPadding: self.leftPadding
        rightPadding: self.rightPadding
        bottomPadding: 0
        background: null
        contentItem: RowLayout {
            spacing: 12
            UiLabel {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: self.title
                typography: Theme.typography.titleMSemibold
                color: self.colors.textPrimary
                wrapMode: Text.Wrap
            }
            UiIconButton {
                variant: UiButton.Neutral
                Accessible.id: self.accessibleId ? self.accessibleId + '_close_btn' : ''
                colors: self.colors
                text: qsTrId('id_close')
                iconName: Theme.icons.x
                size: UiButton.Small
                visible: self.canDismiss
                disabled: !self.canDismiss
                onClicked: self.reject()
            }
        }
    }
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
