import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    readonly property bool denied: DeviceManager.bluetoothPermission === Qt.Denied
    readonly property bool missing: DeviceManager.bluetoothPermission === Qt.Granted && !DeviceManager.bluetoothAvailable
    readonly property bool off: DeviceManager.bluetoothPermission === Qt.Granted && DeviceManager.bluetoothAvailable && !DeviceManager.bluetoothEnabled
    Layout.alignment: Qt.AlignCenter
    Layout.maximumWidth: 360
    id: self
    spacing: 12
    visible: self.denied || self.missing || self.off
    Image {
        Layout.alignment: Qt.AlignHCenter
        source: 'qrc:/svg2/warning.svg'
    }
    Label {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        horizontalAlignment: Label.AlignHCenter
        font.pixelSize: 14
        font.weight: 400
        opacity: 0.8
        wrapMode: Label.WordWrap
        text: {
            if (self.denied) return 'Bluetooth access is denied, so Jade can only be found over USB. Allow Bluetooth access in the system settings to connect over Bluetooth.'
            if (self.missing) return 'No Bluetooth adapter was found, so Jade can only be found over USB.'
            return 'Bluetooth is turned off, so Jade can only be found over USB. Turn on Bluetooth to connect over Bluetooth.'
        }
    }
    RegularButton {
        Layout.alignment: Qt.AlignHCenter
        text: 'Open System Settings'
        visible: {
            if (self.denied) return Qt.platform.os === 'osx'
            if (self.off) return Qt.platform.os === 'osx' || Qt.platform.os === 'windows'
            return false
        }
        onClicked: {
            if (self.denied) return Qt.openUrlExternally('x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth')
            Qt.openUrlExternally(Qt.platform.os === 'osx' ? 'x-apple.systempreferences:com.apple.BluetoothSettings' : 'ms-settings:bluetooth')
        }
    }
}
