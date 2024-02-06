import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Page {
    signal advancedClicked()
    signal skipClicked()
    signal firmwareSelected(var firmware)
    required property JadeDevice device
    required property var firmware
    required property bool fetching
    id: self
    padding: 0
    background: Item {
        BusyIndicator {
            anchors.centerIn: parent
            running: self.fetching
        }
    }
    footer: Pane {
        background: null
        padding: 60
        contentItem: RowLayout {
            LinkButton {
                Layout.alignment: Qt.AlignBottom
                id: left_item
                opacity: center_item.opacity
                text: qsTrId('id_more_options')
                enabled: left_item.opacity === 1
                onClicked: self.advancedClicked()
            }
            Item {
                Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(right_item) - UtilJS.effectiveWidth(left_item), 0)
            }
            HSpacer {
            }
            ColumnLayout {
                Layout.fillWidth: false
                visible: self.device.updateRequired
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/svg2/warning.svg'
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 12
                    font.weight: 600
                    text: qsTrId('id_new_jade_firmware_required')
                }
            }
            HSpacer {
            }
            Item {
                Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(left_item) - UtilJS.effectiveWidth(right_item), 0)
            }
            LinkButton {
                Layout.alignment: Qt.AlignBottom
                id: right_item
                text: qsTrId('id_skip')
                visible: !self.device.updateRequired
                onClicked: self.skipClicked()
            }
        }
    }
    contentItem: ColumnLayout {
        id: center_item
        opacity: self.fetching ? 0 : 1
        Behavior on opacity {
            SmoothedAnimation {
                velocity: 3
            }
        }
        VSpacer {
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            foreground: 'qrc:/png/jade_0.png'
            width: 352
            height: 240
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 26
            font.weight: 600
            text: qsTrId('id_firmware_update')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 14
            font.weight: 400
            text: qsTr('Keep your Jade secure, upgrade now to the <b>%1</b> firmware version!').arg(self.firmware.version)
            textFormat: Label.StyledText
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            Layout.topMargin: 20
            text: qsTrId('id_continue')
            enabled: self.device.connected && self.device.status === JadeDevice.StatusIdle
            onClicked: self.firmwareSelected(self.firmware)
        }
        VSpacer {
        }
    }

    Component {
        id: unlock_view
        JadeUnlockView {
            context: null
            device: self.device
            onUnlockFinished: (context) => self.firmwareSelected(self.firmware)
            onUnlockFailed: self.StackView.view.pop()
        }
    }
}
