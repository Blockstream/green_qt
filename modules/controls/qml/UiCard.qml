import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.Pane {
    enum Variant { Primary, Secondary }

    property Colors colors: Theme.colors
    property int variant: UiCard.Primary

    id: self
    padding: 24
    background: Rectangle {
        color: self.variant === UiCard.Primary ? self.colors.surfaceBase : 'transparent'
        border.color: self.colors.borderSubtle
        border.width: 1
        radius: 4
    }
}
