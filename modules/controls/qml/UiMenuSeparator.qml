import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.MenuSeparator {
    property Colors colors: Theme.colors

    id: self
    padding: 0
    topPadding: 0
    bottomPadding: 0
    contentItem: UiDivider {
        colors: self.colors
        weight: UiDivider.Bold
    }
}
