import QtQuick
import QtQuick.Effects

Image {
    property color color: 'transparent'

    id: self
    fillMode: Image.PreserveAspectFit
    layer.enabled: self.color.a > 0
    layer.effect: MultiEffect {
        colorization: 1
        colorizationColor: self.color
    }
}
