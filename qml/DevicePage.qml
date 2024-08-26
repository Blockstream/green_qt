import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal deviceSelected(Device device)
    signal removeClicked()
    signal closeClicked()
    required property Wallet wallet
    property bool login: true
    function update() {
        if (timer.running) return
        if (stack_view.depth === 1 && devices_model.rowCount > 0) {
            stack_view.push(devices_view)
        } else if (stack_view.depth > 1 && devices_model.rowCount === 0) {
            stack_view.pop()
        }
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
            Loader {
                Layout.alignment: Qt.AlignCenter
                id: auto_login_loader
                active: stack_view.currentItem === view && self.login && device_repeater.count === 1 && device_repeater.itemAt(0).item.device.connected && device_repeater.itemAt(0).item.enabled
                sourceComponent: ColumnLayout {
                    LinkButton {
                        Layout.alignment: Qt.AlignCenter
                        text: 'Cancel Automatic Login'
                        onClicked: self.login = false
                    }
                    Item {
                        Layout.alignment: Qt.AlignCenter
                        Layout.bottomMargin: 60
                        Layout.minimumWidth: 400
                        Layout.minimumHeight: 4
                        Rectangle {
                            anchors.centerIn: parent
                            implicitHeight: 2
                            radius: 1
                            color: '#00B45A'
                            NumberAnimation on implicitWidth {
                                easing.type: Easing.OutCubic
                                from: 400
                                to: 0
                                duration: 3000
                                onFinished: {
                                    device_repeater.itemAt(0).item.trigger()
                                    self.login = false
                                }
                            }
                            opacity: Math.min(1, implicitWidth / 20)
                        }
                    }
                }
            }

        }
    }
    Component {
        id: jade_device
        JadeDeviceDelegate {
            id: delegate
            device: _device
            function trigger() {
                self.login = false
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
                self.login = false
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
