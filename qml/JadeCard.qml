import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    id: self
    visible: self.context.wallet.deviceDetails?.type === 'jade'
    readonly property var latestFirmware: {
        for (const firmware of update_controller.firmwares) {
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
        id: update_controller
        index: firmware_controller.index
        device: self.context?.device
    }

    contentItem: RowLayout {
        ColumnLayout {
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: qsTrId('id_hardware_wallet')
            }
            VSpacer {
            }
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 20
                font.weight: 600
                text: self.context.wallet.deviceDetails.name
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
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/png/jade_card.png'
        }
        ColumnLayout {
            visible: self.context?.device?.connected ?? false
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: qsTrId('id_firmware')
            }
            VSpacer {
            }
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 20
                font.weight: 600
                text: self.context?.device?.version
            }
            PrimaryButton {
                text: qsTrId('id_firmware_update')
                visible: !self.runningLatest
                onClicked: update_firmware_dialog.createObject(self).open()
            }
            LinkButton {
                visible: self.runningLatest
                text: 'Up to date'
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
