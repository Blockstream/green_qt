import Blockstream.Controls
import Blockstream.Green
import Blockstream.Green.Core
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

UiCard {
    signal connectUsbClicked(JadeDevice device)
    signal connectBluetoothClicked(JadeDevice device)
    required property JadeDevice device
    // Only reported since firmware 1.0.42
    readonly property string jadeInterface: self.device.versionInfo?.JADE_INTERFACE ?? 'NONE'
    Layout.alignment: Qt.AlignCenter
    Layout.minimumWidth: 350
    id: self
    enabled: !self.device.connected || self.device.status === JadeDevice.StatusIdle
    padding: 20
    opacity: self.enabled ? 1 : 0.4
    contentItem: RowLayout {
        spacing: 10
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
        UiIcon {
            name: Theme.icons.qrCode
            visible: self.jadeInterface === 'QR'
        }
        UiButton {
            iconName: Theme.icons.usb
            size: UiButton.ExtraSmall
            text: 'USB'
            variant: UiButton.Secondary
            enabled: self.jadeInterface === 'NONE' || self.jadeInterface === 'SERIAL'
            visible: self.device.connected && self.device.usbAvailable && self.jadeInterface !== 'QR'
            onClicked: self.connectUsbClicked(self.device)
        }
        UiButton {
            iconName: Theme.icons.bluetooth
            size: UiButton.ExtraSmall
            text: qsTrId('id_bluetooth')
            variant: UiButton.Secondary
            enabled: self.jadeInterface === 'NONE' || self.jadeInterface === 'BLE'
            visible: (self.device.bluetoothState === JadeDevice.BluetoothUnpaired || self.device.connected && self.device.bluetoothAvailable) && self.jadeInterface !== 'QR'
            onClicked: self.connectBluetoothClicked(self.device)
        }
    }
}
