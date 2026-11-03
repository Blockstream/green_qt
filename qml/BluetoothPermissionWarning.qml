import Blockstream.Controls
import Blockstream.Green
import Blockstream.Green.Core
import Blockstream.Theme
import QtQuick
import QtQuick.Layouts

UiAlertBanner {
    readonly property bool denied: DeviceManager.bluetoothPermission === Qt.Denied
    readonly property bool missing: DeviceManager.bluetoothPermission === Qt.Granted && !DeviceManager.bluetoothAvailable
    readonly property bool off: DeviceManager.bluetoothPermission === Qt.Granted && DeviceManager.bluetoothAvailable && !DeviceManager.bluetoothEnabled
    Layout.fillWidth: true
    id: self
    spacing: 12
    dismissible: false
    variant: UiAlertBanner.Info
    visible: self.denied || self.missing || self.off
    title: {
        if (self.denied) return 'Grant Blockstream Bluetooth permission'
        if (self.missing) return 'Bluetooth is not available'
        return 'Bluetooth is off'
    }
    description: {
        if (self.denied) return 'Allow access in System Settings to connect Jade wirelessly. USB still works.'
        if (self.missing) return 'No Bluetooth adapter was found, so Jade can only be found over USB.'
        return 'Turn on Bluetooth to connect Jade wirelessly. USB still works.'
    }
    UiButton {
        size: UiButton.ExtraSmall
        variant: UiButton.SecondaryInverted
        colors: self.colors
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
