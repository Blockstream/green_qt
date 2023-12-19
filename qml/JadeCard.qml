import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    readonly property var latestFirmware: {
        for (const firmware of controller.firmwares) {
            if (firmware.latest) {
                return firmware
            }
        }
        return null
    }
    readonly property bool runningLatest: {
        return self.context.device?.version === self.latestFirmware?.version
    }
    JadeFirmwareCheckController {
        id: controller
        index: firmware_controller.index
        device: self.context?.device
    }
    id: self
    visible: self.context.wallet.deviceDetails?.type === 'jade'
    TapHandler {
        enabled: self.context.device?.connected ?? false
        onTapped: update_firmware_dialog.createObject(self).open()
    }
    background: Item {
        Image {
            id: image
            x: details_column.width
            anchors.verticalCenter: parent.verticalCenter
            source: 'qrc:/png/jade_card.png'
        }
    }
    headerItem: RowLayout {
        Label {
            Layout.alignment: Qt.AlignCenter
            font.capitalization: Font.AllUppercase
            font.pixelSize: 12
            font.weight: 400
            opacity: 0.6
            text: qsTrId('id_hardware_wallet')
        }
        HSpacer {
            Layout.minimumHeight: 28
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: fw_column.width
            font.capitalization: Font.AllUppercase
            font.pixelSize: 12
            font.weight: 400
            opacity: 0.6
            text: qsTrId('id_firmware')
            visible: !self.runningLatest
        }
    }
    contentItem: RowLayout {
        ColumnLayout {
            Layout.rightMargin: image.width
            id: details_column
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 20
                font.weight: 600
                text: self.context.wallet.deviceDetails?.name ?? ''
            }
            RowLayout {
                Layout.fillHeight: false
                Rectangle {
                    Layout.alignment: Qt.AlignCenter
                    color: self.context.device?.connected ? '#01B35A' : 'red'
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: 5
                }
                Label {
                    Layout.fillWidth: true
                    font.capitalization: Font.AllUppercase
                    font.pixelSize: 16
                    font.weight: 400
                    opacity: 0.8
                    text: self.context.device?.connected ? 'connected' : 'disconnected'
                }
            }
            VSpacer {
            }
        }
        ColumnLayout {
            id: fw_column
            visible: !self.runningLatest
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 20
                font.weight: 600
                text: self.context?.device?.version ?? ''
            }
            PrimaryButton {
                text: qsTrId('id_firmware_update')
                onClicked: update_firmware_dialog.createObject(self).open()
            }
            VSpacer {
            }
        }
    }

    Component {
        id: update_firmware_dialog
        JadeUpdateDialog2 {
            context: self.context
            device: self.context.device
        }
    }
}
