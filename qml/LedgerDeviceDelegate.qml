import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    signal selected(LedgerDevice device)
    required property LedgerDevice device
    Layout.alignment: Qt.AlignCenter
    Layout.minimumWidth: 350
    onClicked: self.selected(self.device)
    id: self
    enabled: {
        if (!self.device.connected) return false
        if (!self.device.compatible) return false
        switch (self.device.appName) {
        case 'Bitcoin':
        case 'Bitcoin Legacy':
        case 'Bitcoin Test':
        case 'Bitcoin Test Legacy':
        case 'Liquid':
        case 'Liquid Test':
            return true
        default:
            return false
        }
    }
    padding: 20
    opacity: self.enabled ? 1 : 0.6
    background: Rectangle {
        color: Qt.lighter('#222226', self.enabled && self.hovered ? 1.2 : 1)
        radius: 5
        Rectangle {
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            visible: self.visualFocus
        }
    }
    contentItem: RowLayout {
        spacing: 20
//        Image {
//            Layout.alignment: Qt.AlignCenter
//            source: 'qrc:/svg2/lock-simple-thin.svg'
//            visible: self.device.connected && self.device.state === JadeDevice.StateLocked
//        }
        Label {
            Layout.fillWidth: true
            font.pixelSize: 16
            font.weight: 700
            color: '#FFF'
            text: self.device.name
        }
        Label {
            opacity: 0.8
            text: {
                switch (self.device?.state ?? LedgerDevice.StateUnknown) {
                    case LedgerDevice.StateApp:
                        return self.device.appName + ' ' + self.device.appVersion
                    case LedgerDevice.StateDashboard:
                        return qsTrId('id_firmware') + ' ' + self.device.appVersion
                    case LedgerDevice.StateLocked:
                        return qsTrId('id_locked')
                    case LedgerDevice.StateUnknown:
                    default:
                        return qsTrId('id_loading')
                }
            }
        }
//        CircleButton {
//            icon.source: 'qrc:/svg2/eject-simple-thin.svg'
//            visible: !self.device.connected
//            onClicked: DeviceManager.removeDevice(self.device)
//        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/right.svg'
            visible: self.enabled
        }
    }
}
