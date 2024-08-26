import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

VFlickable {
    signal loginClicked()
    signal updateClicked()
    required property JadeDevice device
    required property var latestFirmware
    readonly property bool debug: Qt.application.arguments.indexOf('--debugjade') > 0
    id: self
    enabled: (self.device?.connected ?? false) && self.device.status === JadeDevice.StatusIdle
    spacing: 10
    Item {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 352
        Layout.preferredHeight: 240
        clip: true
        Image {
            anchors.centerIn: parent
            scale: 0.2
            source: 'qrc:/png/background.png'
        }
        Image {
            anchors.centerIn: parent
            scale: 0.2
            source: 'qrc:/png/jade_0.png'
        }
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
        enabled: (self.debug || self.latestFirmware) && self.device.status === JadeDevice.StatusIdle
        text: qsTrId('id_firmware_update')
        onClicked: self.updateClicked()
    }
}
