import QtQuick
import QtQuick.Effects

// TODO: This is a temporary icon component.
// Update it to use a named set of icons instead of a single image file.
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
