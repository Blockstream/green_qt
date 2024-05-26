import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal deviceSelected(LedgerDevice device)
    id: self
    padding: 60
    footerItem: ColumnLayout {
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
    }
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
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
        VSpacer {
        }
    }

    component InstructionsView: Pane {
        Layout.alignment: Qt.AlignCenter
        background: null
        padding: 0
        contentItem: ColumnLayout {
            Item {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 352
                Layout.preferredHeight: 352
                Image {
                    anchors.centerIn: parent
                    scale: 0.2
                    source: 'qrc:/png/background.png'
                }
                Image {
                    anchors.centerIn: parent
                    scale: 0.2
                    source: 'qrc:/png/ledger_3d.png'
                }
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
