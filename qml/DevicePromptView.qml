import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GStackView {
    required property DevicePrompt prompt
    required property Context context
    function update() {
        if (self.depth === 1 && devices_model.rowCount > 0) {
            self.push(devices_view)
        } else if (self.depth > 1 && devices_model.rowCount === 0) {
            self.pop()
        }
    }
    function select(device) {
        const context = self.context
        switch (device.state) {
        case JadeDevice.StateReady:
            // Unlocked but not yet identified as this wallet, which the context
            // requires before taking the device.
            if (device.session?.xpubHashId === context.xpubHashId) {
                self.prompt.select(device)
                break
            }
            // fallthrough
        case JadeDevice.StateTemporary:
        case JadeDevice.StateLocked:
            self.push(jade_unlock_view, { context, device, showRemember: false })
            break
        case JadeDevice.StateUninitialized:
        case JadeDevice.StateUnsaved:
            // TODO: show view to jump to onboarding
            break
        }
    }
    Component.onCompleted: self.update()
    DeviceDiscoveryRequest {
        active: self.visible
    }
    DeviceListModel {
        id: devices_model
        onRowCountChanged: self.update()
    }
    id: self
    initialItem: ColumnLayout {
        VSpacer {
        }
        Loader {
            Layout.alignment: Qt.AlignCenter
            sourceComponent: {
                switch (self.context.wallet.login.device.type) {
                case 'jade': return jade_view
                default: return null
                }
            }
        }
        VSpacer {
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            Layout.bottomMargin: 60
            color: '#FFF'
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_looking_for_device')
        }
        BluetoothPermissionWarning {
            Layout.bottomMargin: 60
        }
    }

    Component {
        id: devices_view
        ColumnLayout {
            spacing: 10
            VSpacer {
            }
            Repeater {
                id: device_repeater
                model: devices_model
                delegate: Loader {
                    property Device _device: modelData
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 325
                    id: loader
                    sourceComponent: {
                        switch (loader._device.type) {
                        case Device.BlockstreamJade: return jade_device
                        }
                    }
                }
            }
            VSpacer {
            }
        }
    }

    Component {
        id: jade_device
        JadeDeviceDelegate {
            id: delegate
            device: _device
            enabled: {
                const device = delegate.device
                if (!device.connected) return true
                if (device.status !== JadeDevice.StatusIdle) return false
                const context = self.context
                switch (device.state) {
                case JadeDevice.StateReady:
                    return true
                case JadeDevice.StateTemporary:
                case JadeDevice.StateLocked:
                    return true
                case JadeDevice.StateUninitialized:
                case JadeDevice.StateUnsaved:
                    return false
                }
            }
            onConnectUsbClicked: (device) => {
                device.selectConnection(JadeDevice.USB)
                self.select(device)
            }
            onConnectBluetoothClicked: (device) => {
                if (device.connected && device.bluetoothAvailable) {
                    device.selectConnection(JadeDevice.Bluetooth)
                    self.select(device)
                } else {
                    self.push(jade_bluetooth_pair_page, { device })
                }
            }
        }
    }

    Component {
        id: jade_bluetooth_pair_page
        JadeBluetoothPairPage {
            onDeviceSelected: (device) => {
                self.pop(StackView.Immediate)
                self.select(device)
            }
        }
    }

    Component {
        id: jade_unlock_view
        JadeUnlockView {
            id: view
            onUnlockFinished: (context) => {
                // Left unattached when it holds another wallet's keys.
                if (context.device === view.device) {
                    self.prompt.select(view.device)
                } else {
                    self.pop()
                }
            }
            onUnlockFailed: self.pop()
        }
    }

    Component {
        id: jade_view
        JadeInstructionsView {
        }
    }
}
