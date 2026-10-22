import Blockstream.Theme
import QtQuick
import QtQuick.Effects

Item {
    property Colors colors: Theme.colors
    property real pointerX: 0.5
    property real pointerY: 0
    property real pointerXOffset: 0
    property real radius: 10

    id: self
    Rectangle {
        id: pointer
        x: self.pointerX * self.width - width / 2 + self.pointerXOffset
        y: self.pointerY * self.height - height / 2
        width: 9
        height: 9
        rotation: 45
        color: self.colors.borderBold
    }
    Rectangle {
        id: surface
        anchors.fill: parent
        color: self.colors.surfaceOverlay
        border.color: self.colors.borderBold
        border.width: 0.5
        radius: self.radius
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: self.colors.overlayScrim
            shadowBlur: 1
            shadowVerticalOffset: 0
            blurMax: 64
        }
    }
    Rectangle {
        anchors.centerIn: pointer
        width: 7.5
        height: 7.5
        rotation: 45
        color: self.colors.surfaceOverlay
    }
}
