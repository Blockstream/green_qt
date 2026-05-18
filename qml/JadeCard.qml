import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    signal detailsClicked

    readonly property JadeDevice device: self.context?.device instanceof JadeDevice ? self.context.device : null

    function isJadeLocked() {
        return !!self.device?.connected && self.device?.state === JadeDevice.StateLocked
    }

    function getJadeStatusOptions () {
        if (!self.device?.connected) {
            return { text: qsTrId('id_disconnected'), color: '#FF6467' }
        }

        if (self.isJadeLocked()) {
            return { text: qsTrId('id_locked'), color: '#FDC700' }
        }

        return { text: qsTrId('id_connected'), color: '#00C60D' }
    }

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
    headerItem: Label {
        topPadding: 3
        bottomPadding: 6
        color: '#FFF'
        font.pixelSize: 12
        font.weight: 400
        opacity: 0.6
        text: qsTrId('id_hardware_wallet')
    }
    contentItem: ColumnLayout {
        spacing: 4
        RowLayout {
            spacing: 8
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 22
                font.weight: 600
                text: self.context.wallet.login?.device?.name ?? ''
            }
            AbstractButton {
                contentItem: Image {
                    Layout.alignment: Qt.AlignCenter
                    Layout.maximumWidth: 18
                    Layout.maximumHeight: 18
                    source: 'qrc:/svg2/info_blue.svg'
                }
                onClicked: self.detailsClicked()
            }
        }
        RowLayout {
            Layout.fillHeight: false
            spacing: 4
            Rectangle {
                Layout.alignment: Qt.AlignCenter
                color: self.getJadeStatusOptions().color
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
            }
            Label {
                font.pixelSize: 14
                font.weight: 400
                color: '#A0A0A0'
                text: self.getJadeStatusOptions().text
            }
            LinkButton {
                text: qsTrId('id_unlock')
                visible: self.isJadeLocked()
                enabled: unlock_controller.monitor?.idle ?? true
                onClicked: unlock_controller.unlock()
            }
        }
        LinkButton {
            visible: {
                const latestFirmware = controller.firmwares.find(firmware => firmware.latest)
                return !!latestFirmware && self.device?.version !== latestFirmware.version
            }
            textColor: '#FDC700'
            font.pixelSize: 12
            text: qsTrId('id_new_firmware_available')
            onClicked: update_firmware_dialog.createObject(self).open()
        }
        VSpacer {
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
