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
            visible: !self.device.connected && self.device.bluetoothState === JadeDevice.BluetoothNone
            onClicked: DeviceManager.removeDevice(self.device)
        }
        RegularButton {
            font.pixelSize: 14
            topPadding: 8
            bottomPadding: 8
            icon.source: 'qrc:/svg2/bluetooth.svg'
            text: self.device.bluetoothState === JadeDevice.BluetoothPairing ? 'Pairing...' : 'Pair'
            enabled: self.device.bluetoothState === JadeDevice.BluetoothUnpaired
            visible: !self.device.connected && (self.device.bluetoothState === JadeDevice.BluetoothUnpaired || self.device.bluetoothState === JadeDevice.BluetoothPairing)
            onClicked: self.device.pairBluetooth()
        }
        Label {
            font.pixelSize: 16
            font.weight: 700
            color: '#FFF'
            text: self.device.bluetoothPin
            visible: self.device.bluetoothState === JadeDevice.BluetoothConfirmingPin
        }
        RegularButton {
            font.pixelSize: 14
            topPadding: 8
            bottomPadding: 8
            text: 'Same code on Jade'
            visible: self.device.bluetoothState === JadeDevice.BluetoothConfirmingPin
            onClicked: self.device.confirmBluetoothPin(true)
        }
        LinkButton {
            text: qsTrId('id_cancel')
            visible: self.device.bluetoothState === JadeDevice.BluetoothConfirmingPin
            onClicked: self.device.confirmBluetoothPin(false)
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
