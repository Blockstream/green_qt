import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ProgressBar {
    property Colors colors: Theme.colors
    id: self
    implicitWidth: 200
    implicitHeight: 8
    padding: 0
    background: Rectangle {
        radius: 4
        color: self.colors.surfaceSunken
    }
    contentItem: Item {
        clip: true
        Rectangle {
            id: fill
            property real phase: 0
            x: self.indeterminate ? (phase * 1.3 - 0.3) * parent.width : self.mirrored ? parent.width - width : 0
            width: parent.width * (self.indeterminate ? 0.3 : self.position)
            height: parent.height
            radius: 4
            color: self.enabled ? self.colors.actionPrimary : self.colors.actionDisabled
            NumberAnimation on phase {
                from: 0
                to: 1
                duration: 1200
                loops: Animation.Infinite
                running: self.indeterminate && self.visible
            }
        }
    }
}
