import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal deviceSelected(Device device)
    signal removeClicked()
    required property Wallet wallet
    function update() {
        if (timer.running) return
        if (stack_view.depth === 1 && devices_model.rowCount > 0) {
            stack_view.push(devices_view)
        } else if (stack_view.depth > 1 && devices_model.rowCount === 0) {
            stack_view.pop()
        }
    }
    DeviceDiscoveryRequest {
        active: self.visible && self.StackView.status === StackView.Active
    }
    DeviceListModel {
        id: devices_model
        onRowCountChanged: self.update()
    }
    Timer {
        id: timer
        interval: 500
        running: true
        onTriggered: self.update()
    }

    id: self
    title: self.wallet.name
    leftItem: BackButton {
        text: qsTrId('id_wallets')
        onClicked: self.closeClicked()
        visible: WalletManager.wallets.length > 1
    }
    rightItem: WalletOptionsButton {
        wallet: self.wallet
        onRemoveClicked: self.removeClicked()
        onCloseClicked: self.closeClicked()
    }
    contentItem: GStackView {
        id: stack_view
        initialItem: VFlickable {
            Loader {
                Layout.alignment: Qt.AlignCenter
                sourceComponent: {
                    switch (self.wallet.login?.device?.type) {
                    case 'jade': return jade_view
                    default: return null
                    }
                }
            }
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
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
    }

    Component {
        id: devices_view
        ColumnLayout {
            id: view
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
                        case Device.LedgerNanoS: return ledger_device
                        case Device.LedgerNanoX: return ledger_device
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
            function trigger() {
                self.deviceSelected(delegate.device)
            }
            onSelected: delegate.trigger()
        }
    }
    Component {
        id: ledger_device
        LedgerDeviceDelegate {
            id: delegate
            device: _device
            function trigger() {
                self.deviceSelected(delegate.device)
            }
            onSelected: delegate.trigger()
        }
    }

    Component {
        id: jade_view
        JadeInstructionsView {
        }
    }
}
