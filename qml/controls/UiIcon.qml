import Blockstream.Theme
import QtQuick
import QtQuick.Effects

Item {
    property string name: ""
    property real size: 24
    property color color: Theme.colors.textPrimary

    readonly property url source: Theme.iconNames.has(self.name) ? `qrc:/ui-icons/${self.name}.svg` : ''

    id: self
    visible: self.source.toString().length > 0
    implicitWidth: Math.max(0, self.size)
    implicitHeight: Math.max(0, self.size)
    Accessible.ignored: true

    Image {
        property color color: Qt.rgba(self.color.r, self.color.g, self.color.b, 1)

        id: icon_image
        anchors.fill: parent
        source: self.source
        sourceSize.width: Math.ceil(self.width)
        sourceSize.height: Math.ceil(self.height)
        fillMode: Image.PreserveAspectFit
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: icon_image.color
        }
        opacity: self.color.a
    }
}
