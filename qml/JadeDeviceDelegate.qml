import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Control {
    signal selected(JadeDevice device)
    required property JadeDevice device
    function select(type) {
        self.device.selectConnection(type)
        self.selected(self.device)
    }
    Layout.alignment: Qt.AlignCenter
    Layout.minimumWidth: 350
    id: self
    enabled: !self.device.connected || self.device.status === JadeDevice.StatusIdle
    padding: 20
    opacity: self.enabled ? 1 : 0.4
    background: Rectangle {
        color: '#262626'
        radius: 5
    }
    contentItem: RowLayout {
        spacing: 20
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/lock-simple-thin.svg'
            visible: self.device.connected && self.device.state === JadeDevice.StateLocked
        }
        Label {
            Layout.fillWidth: true
            font.pixelSize: 16
            font.weight: 700
            color: '#FFF'
            text: self.device.name
        }
        CircleButton {
            icon.source: 'qrc:/svg2/eject-simple-thin.svg'
            visible: !self.device.connected
            onClicked: DeviceManager.removeDevice(self.device)
        }
        RegularButton {
            font.pixelSize: 14
            topPadding: 8
            bottomPadding: 8
            icon.source: 'qrc:/svg2/usb.svg'
            text: 'USB'
            visible: self.device.connected && self.device.usbAvailable
            onClicked: self.select(JadeDevice.USB)
        }
        RegularButton {
            font.pixelSize: 14
            topPadding: 8
            bottomPadding: 8
            icon.source: 'qrc:/svg2/bluetooth.svg'
            text: qsTrId('id_bluetooth')
            visible: self.device.connected && self.device.bluetoothAvailable
            onClicked: self.select(JadeDevice.Bluetooth)
        }
    }
}
