import Blockstream.Green
import QtQuick
import QtQuick.Layouts

import "util.js" as UtilJS

Image {
    property Asset asset
    property real size: 32
    source: UtilJS.iconFor(asset)
    Layout.preferredHeight: size
    Layout.preferredWidth: size
    height: size
    width: size
    fillMode: Image.PreserveAspectFit
    mipmap: true
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        border.width: 1
        border.color: '#FFF'
        color: 'transparent'
    }
}
