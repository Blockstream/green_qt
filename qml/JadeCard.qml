import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    signal detailsClicked

    // Once disconnected the wallet has no device until one is attached again, so
    // offer a reconnected Jade with the same name to be unlocked from here. It is
    // kept while unlocking, when it is no longer locked but not yet identified,
    // and dropped once identified as another wallet.
    readonly property JadeDevice device: {
        if (self.context?.device instanceof JadeDevice) return self.context.device
        const name = self.context?.wallet?.login?.device?.name
        if (!name) return null
        for (let i = 0; i < jade_devices.count; ++i) {
            const device = jade_devices.objectAt(i)?.device
            if (!(device instanceof JadeDevice) || !device.connected || device.name !== name) continue
            if (device.session && device.session.xpubHashId !== self.context.xpubHashId) continue
            return device
        }
        return null
    }

    readonly property var status: {
        if (!self.device?.connected || self.context?.device !== self.device) {
            return { text: qsTrId('id_disconnected'), color: '#FF6467', action: 'Connect' }
        }

        if (!!self.device?.connected && self.device?.state === JadeDevice.StateLocked) {
            return { text: qsTrId('id_locked'), color: '#FDC700', action: qsTrId('id_unlock') }
        }

        return { text: qsTrId('id_connected'), color: '#00C60D' }
    }

    Component.onCompleted: firmware_controller.check(self.device)
    DeviceDiscoveryRequest {
        active: self.visible && !self.device?.connected
    }
    Instantiator {
        id: jade_devices
        model: DeviceListModel {
            type: Device.BlockstreamJade
        }
        delegate: QtObject {
            required property Device device
        }
    }
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
                color: self.status.color
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
            }
            Label {
                font.pixelSize: 14
                font.weight: 400
                color: '#A0A0A0'
                text: self.status.text
            }
            LinkButton {
                text: self.status.action ?? ''
                visible: !!self.status.action
                onClicked: {
                    const drawer = jade_connect_drawer.createObject(self)
                    drawer.open()
                }
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
            onClicked: update_firmware_drawer.createObject(self).open()
        }
        VSpacer {
        }
    }

    Component {
        id: update_firmware_drawer
        JadeUpdateDrawer {
            device: self.device
        }
    }
    Component {
        id: jade_connect_drawer
        JadeConnectDrawer {
            id: drawer
            // Unlocked on the wallet's context, which takes the device back once
            // it proves to hold the wallet keys; the page reports a mismatch.
            context: self.context
            wallet: self.context.wallet
            onDeviceSelected: drawer.close()
        }
    }
}
