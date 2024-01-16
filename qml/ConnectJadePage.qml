import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal deviceSelected(JadeDevice device)
    id: self
    padding: 60
    rightItem: LinkButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        text: qsTrId('id_setup_guide')
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/19629901272345-Set-up-Jade')
    }
    footerItem: ColumnLayout {
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            color: '#FFF'
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_looking_for_device')
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            text: qsTrId('id_troubleshoot')
            onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900005443223-Fix-issues-connecting-Jade-via-USB')
        }
    }
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
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
        VSpacer {
        }
    }
}
