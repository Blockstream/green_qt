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
    Repeater {
        id: device_repeater
        model: DeviceListModel {
            type: Device.BlockstreamJade
        }
        delegate: JadeDeviceDelegate {
            onSelected: (device) => self.deviceSelected(device)
        }
    }
    JadeInstructionsView {
        visible: device_repeater.count === 0
    }
    BusyIndicator {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        Layout.topMargin: 10
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 8
        color: '#FFF'
        font.pixelSize: 12
        font.weight: 600
        text: qsTrId('id_looking_for_device')
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
