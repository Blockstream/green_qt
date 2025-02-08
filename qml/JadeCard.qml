import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    signal detailsClicked
    readonly property JadeDevice device: self.context?.device instanceof JadeDevice ? self.context.device : null
    readonly property var latestFirmware: {
        for (const firmware of controller.firmwares) {
            if (firmware.latest) {
                return firmware
            }
        }
        return null
    }
    readonly property bool runningLatest: {
        return self.device?.version === self.latestFirmware?.version
    }
    readonly property bool debug: Qt.application.arguments.indexOf('--debugjade') > 0

    Component.onCompleted: firmware_controller.check(self.device)
    JadeFirmwareController {
        id: firmware_controller
    }
    JadeFirmwareCheckController {
        id: controller
        index: firmware_controller.index
        device: self.device
    }
    id: self
    visible: self.context.wallet.login?.device?.type === 'jade'
    TapHandler {
        enabled: self.device?.connected ?? false
        onTapped: {
          if (self.debug) {
            self.detailsClicked()
          } else {
            update_firmware_dialog.createObject(self).open()
          }
        }
    }
    background: Item {
        Image {
            id: image
            x: details_column.width
            anchors.verticalCenter: parent.verticalCenter
            source: {
                if (self.device) {
                    const type = self.device.versionInfo?.BOARD_TYPE
                    return type === 'JADE_V2' ? 'qrc:/png/jade2_card.png' : 'qrc:/png/jade_card.png'
                }
                return ''
            }
        }
    }
    headerItem: RowLayout {
        Label {
            Layout.alignment: Qt.AlignCenter
            color: '#FFF'
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
                text: self.context.wallet.login?.device?.name ?? ''
            }
            RowLayout {
                Layout.fillHeight: false
                Rectangle {
                    Layout.alignment: Qt.AlignCenter
                    color: self.device?.connected ? '#01B35A' : 'red'
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
                    text: self.device?.connected ? 'connected' : 'disconnected'
                }
            }
            RegularButton {
                visible: {
                    if (!self.debug) return false
                    switch (self.device?.state) {
                    case JadeDevice.StateTemporary:
                    case JadeDevice.StateLocked:
                        return true
                    default:
                        return false
                    }
                }
                text: qsTrId('id_unlock')
                onClicked: unlock_controller.unlock()
                busy: !(unlock_controller.monitor?.idle ?? true)
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
                text: self.device?.version ?? ''
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
            device: self.device
        }
    }
    JadeUnlockController {
        id: unlock_controller
        context: self.context
        device: self.device
        onHttpRequest: (request) => {
            const dialog = http_request_dialog.createObject(self, { request, context: self.context })
            dialog.open()
        }
    }
    Component {
        id: http_request_dialog
        JadeHttpRequestDialog {
        }
    }
}
