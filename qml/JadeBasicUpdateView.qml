import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal advancedClicked()
    signal skipClicked()
    signal firmwareSelected(var firmware)
    required property JadeDevice device
    required property var firmware
    required property bool fetching
    id: self
    title: qsTrId('id_firmware_upgrade')
    footerItem: ColumnLayout {
        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: self.fetching
            visible: self.fetching
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
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
        LinkButton {
            Layout.alignment: Qt.AlignHCenter
            id: right_item
            text: qsTrId('id_skip')
            visible: !self.device.updateRequired
            onClicked: self.skipClicked()
        }
    }
    contentItem: ColumnLayout {
        clip: true
        VSpacer {
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            foreground: UtilJS.jadeImage(self.device, 0)
            width: 352
            height: 240
        }
        Label {
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: qsTr('Keep your Jade secure, upgrade to firmware version <b>%1</b> now!').arg(self.firmware.version)
            textFormat: Label.StyledText
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            text: qsTrId('id_continue')
            enabled: self.device.connected && self.device.status === JadeDevice.StatusIdle
            onClicked: self.firmwareSelected(self.firmware)
        }
        LinkButton {
            Layout.alignment: Qt.AlignHCenter
            id: left_item
            text: qsTrId('id_more_options')
            enabled: left_item.opacity === 1
            onClicked: self.advancedClicked()
        }
        VSpacer {
        }
    }
}
