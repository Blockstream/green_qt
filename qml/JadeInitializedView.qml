import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    signal loginClicked()
    signal updateClicked()
    required property JadeDevice device
    id: self
    enabled: (self.device?.connected ?? false) && self.device.status === JadeDevice.StatusIdle
    spacing: 10
    VSpacer {
    }
    Image {
        Layout.alignment: Qt.AlignCenter
        source: 'qrc:/png/onboard_jade_1.png'
    }
    PrimaryButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        text: qsTrId('id_login')
        onClicked: self.loginClicked()
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        enabled: self.device.status === JadeDevice.StatusIdle
        text: qsTrId('id_firmware_update')
        onClicked: self.updateClicked()
    }
    VSpacer {
    }
}
