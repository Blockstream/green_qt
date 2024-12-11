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
    readonly property bool debug: Qt.application.arguments.indexOf('--debugjade') > 0

    JadeFirmwareCheckController {
        id: controller
        index: firmware_controller.index
        device: {
            const device = self.context?.device
            return device instanceof JadeDevice ? device : null
        }
    }
    id: self
    visible: self.context.wallet.login?.device?.type === 'jade'
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
            Label {
                font.pixelSize: 8
                text: [
                    'state:' + (self.context?.device?.versionInfo?.JADE_STATE ?? 'n/a'),
                    'wallet: ' + (self.context?.xpubHashId ?? 'n/a'),
                    'jade: ' + (self.context?.device?.session?.xpubHashId ?? 'n/a')
                ].join('\n')
                visible: self.debug
            }
            RegularButton {
                visible: {
                    if (!self.debug) return false
                    switch (self.context.device?.state) {
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
    JadeUnlockController {
        id: unlock_controller
        context: self.context
        device: {
            const device = self.context?.device
            return device instanceof JadeDevice ? device : null
        }
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
