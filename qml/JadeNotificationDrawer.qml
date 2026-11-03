import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

AbstractDrawer {
    signal deviceSelected(JadeDevice device)
    required property JadeDevice device
    Connections {
        target: self.device
        function onConnectedChanged() {
            // Jade reboots during a firmware update, only close before the flow starts
            if (stack_view.depth === 1) self.close()
        }
    }
    id: self
    edge: Qt.RightEdge
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            id: root_page
            title: 'Hardware Wallet Connected'
            rightItem: CloseButton {
                onClicked: self.close()
            }
            JadeConnectFlow {
                id: flow
                page: root_page
                onDeviceReady: (device) => self.deviceSelected(device)
                onCloseClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 20
                VSpacer {
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    opacity: 0.4
                    text: 'A new device has been detected, please set it up to start using it.'
                    wrapMode: Label.WordWrap
                }
                MultiImage {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: 260
                    Layout.preferredWidth: 320
                    foreground: UtilJS.jadeImage(self.device, 0)
                    margins: 30
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    text: 'Set up Jade'
                    onClicked: {
                        if (!self.device.connectionSelected) self.device.selectConnection(JadeDevice.USB)
                        flow.genuineCheck(self.device)
                    }
                }
                LinkButton {
                    Layout.alignment: Qt.AlignCenter
                    text: qsTrId('id_not_now')
                    onClicked: self.close()
                }
                VSpacer {
                }
            }
        }
    }
}
