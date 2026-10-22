import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ScrollIndicator {
    property Colors colors: Theme.colors
    id: self
    padding: 2
    minimumSize: 0.05
    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: 3
        color: self.colors.iconSubtle
        opacity: self.active ? 1 : 0
    }
}
