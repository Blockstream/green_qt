import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal deviceSelected(JadeDevice device)
    signal qrmodeSelected()
    id: self
    footer: null
    padding: 60
    rightItem: LinkButton {
        external: true
        text: qsTrId('id_setup_guide')
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/19629901272345-Set-up-Jade')
    }
    DeviceDiscoveryRequest {
        active: self.visible && self.StackView.status === StackView.Active
    }
    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: 10
        visible: device_repeater.count > 0
        Repeater {
            id: device_repeater
            model: DeviceListModel {
                type: Device.BlockstreamJade
            }
            delegate: JadeDeviceDelegate {
                Layout.fillWidth: true
                onSelected: (device) => self.deviceSelected(device)
            }
        }
    }
    RowLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 10
        spacing: 8
        visible: DeviceManager.bluetoothScanning
        BusyIndicator {
            Layout.preferredHeight: 24
            Layout.preferredWidth: 24
        }
        Label {
            color: '#FFF'
            font.pixelSize: 12
            font.weight: 600
            opacity: 0.6
            text: qsTrId('id_looking_for_device')
        }
    }
    JadeInstructionsView {
        visible: device_repeater.count === 0
    }
    BluetoothPermissionWarning {
        Layout.topMargin: 20
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 360
        Layout.topMargin: 40
        cyan: true
        text: qsTrId('id_connect_via_qr') + ' (Plus & Classic only)'
        onClicked: self.qrmodeSelected()
    }
    LinkButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        Layout.bottomMargin: 20
        external: true
        text: qsTrId('id_troubleshoot')
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900005443223-Fix-issues-connecting-Jade-via-USB')
    }
}
