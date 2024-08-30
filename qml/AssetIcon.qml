import Blockstream.Green
import QtQuick
import QtQuick.Controls
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
        color: '#FFF'
        z: -1
        radius: width / 2
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1 - self.border
        border.width: self.border
        border.color: '#FFF'
        color: 'transparent'
        radius: width / 2
    }
}
