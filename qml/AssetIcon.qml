import Blockstream.Green
import QtQuick
import QtQuick.Layouts

import "util.js" as UtilJS

Image {
    property Asset asset
    property real size: 32
    property real border: 1
    id: self
    source: UtilJS.iconFor(asset)
    Layout.preferredHeight: size
    Layout.preferredWidth: size
    height: size
    width: size
    fillMode: Image.PreserveAspectFit
    mipmap: true
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1 - self.border
        radius: width / 2
        border.width: self.border
        border.color: '#FFF'
        color: 'transparent'
    }
}
