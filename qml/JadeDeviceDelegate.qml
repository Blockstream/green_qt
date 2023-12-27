import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    signal selected(JadeDevice device)
    required property JadeDevice device
    Layout.alignment: Qt.AlignCenter
    Layout.minimumWidth: 350
    onClicked: if (self.device.connected) self.selected(self.device)
    id: self
    enabled: !self.device.connected || self.device.status === JadeDevice.StatusIdle
    padding: 20
    opacity: self.enabled ? 1 : 0.4
    background: Rectangle {
        color: Qt.lighter('#222226', self.enabled && self.hovered ? 1.2 : 1)
        radius: 5
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            visible: self.visualFocus
        }
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
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/right.svg'
            visible: self.device.connected
        }
    }
}
