import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.Popup {
    property Colors colors: Theme.colors
    property real pointerX: 0.5
    property string accessibleId: ''

    id: self
    modal: true
    dim: false
    closePolicy: Basic.Popup.CloseOnEscape | Basic.Popup.CloseOnPressOutside
    padding: 16
    focus: true
    PopupAccessibility {
        popup: self
        accessibleId: self.accessibleId
    }
    background: UiPopupSurface {
        colors: self.colors
        pointerX: self.pointerX
    }
}
