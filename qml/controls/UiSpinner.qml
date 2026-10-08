import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Material

BusyIndicator {
    property real size: 20
    property color color: Theme.colors.textPrimary

    id: self
    implicitWidth: self.size
    implicitHeight: self.size
    padding: 0
    opacity: self.running ? 1 : 0
    Material.accent: self.color
}
