import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    Layout.alignment: Qt.AlignCenter
    Layout.maximumWidth: 360
    id: self
    spacing: 12
    visible: DeviceManager.bluetoothPermission === Qt.Denied
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
        text: 'Bluetooth access is denied, so Jade can only be found over USB. Allow Bluetooth access in the system settings to connect over Bluetooth.'
    }
    RegularButton {
        Layout.alignment: Qt.AlignHCenter
        text: 'Open System Settings'
        visible: Qt.platform.os === 'osx'
        onClicked: Qt.openUrlExternally('x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth')
    }
}
