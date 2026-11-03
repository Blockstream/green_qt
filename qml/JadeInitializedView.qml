import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Layouts

import "util.js" as UtilJS

VFlickable {
    signal loginClicked()
    required property JadeDevice device
    id: self
    enabled: (self.device?.connected ?? false) && self.device.status === JadeDevice.StatusIdle
    spacing: 10
    MultiImage {
        Layout.alignment: Qt.AlignCenter
        foreground: UtilJS.jadeImage(self.device, 0)
        width: 352
        height: 240
    }
    PrimaryButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        text: qsTrId('id_login')
        onClicked: self.loginClicked()
    }
}
