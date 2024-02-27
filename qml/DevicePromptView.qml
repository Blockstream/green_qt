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
    Component.onCompleted: self.update()
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
            function trigger() {
                const device = delegate.device
                const context = self.context
                switch (device.state) {
                case JadeDevice.StateReady:
                    self.prompt.select(delegate.device)
                    break;
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
            id: delegate
            device: _device
            enabled: {
                const device = delegate.device
                if (!device.connected) return true
                if (self.device.status === JadeDevice.StatusIdle) return false
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
            onSelected: delegate.trigger()
        }
    }

    Component {
        id: jade_unlock_view
        JadeUnlockView {
            id: view
            onUnlockFinished: (context) => {
                self.prompt.select(device)
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
