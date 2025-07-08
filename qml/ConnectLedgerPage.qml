import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal deviceSelected(LedgerDevice device)
    id: self
    footer: null
    padding: 60
    Repeater {
        id: device_repeater
        model: DeviceListModel {
            vendor: Device.Ledger
        }
        delegate: LedgerDeviceDelegate {
            onSelected: (device) => self.deviceSelected(device)
        }
    }
    InstructionsView {
        visible: device_repeater.count === 0
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        color: '#FFF'
        font.pixelSize: 12
        font.weight: 600
        text: {
            if (device_repeater.count === 0) {
                return qsTrId('id_looking_for_device')
            }
            if (device_repeater.count === 1) {
                const device = device_repeater.itemAt(0).device
                if (device.state === LedgerDevice.StateDashboard) {
                    return qsTrId('id_ledger_dashboard_detected')
                }
            }
            return ''
        }
        visible: text !== ''
    }
    LinkButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        text: qsTrId('id_troubleshoot')
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/16789393282201-How-do-I-use-my-Ledger-Nano-S-or-X-with-Green#h_01GW4FRJXCRRRGC4QAX0HC02S2')
    }

    component InstructionsView: Pane {
        Layout.alignment: Qt.AlignCenter
        background: null
        padding: 0
        contentItem: ColumnLayout {
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 352
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                mipmap: true
                source: 'qrc:/svg3/Ledger.svg'
                smooth: true
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 450
                horizontalAlignment: Label.AlignHCenter
                font.pixelSize: 26
                font.weight: 600
                text: qsTrId('id_follow_the_instructions_of_your')
                wrapMode: Label.Wrap
            }
        }
    }
}
