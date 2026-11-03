import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

VFlickable {
    signal connectionSelected()
    required property JadeDevice device
    id: self
    spacing: 10
    MultiImage {
        Layout.alignment: Qt.AlignCenter
        foreground: UtilJS.jadeImage(self.device, 0)
        width: 352
        height: 240
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        color: '#FFF'
        font.pixelSize: 16
        font.weight: 600
        text: qsTrId('id_connection')
    }
    JadeDeviceDelegate {
        device: self.device
        onSelected: self.connectionSelected()
    }
}
