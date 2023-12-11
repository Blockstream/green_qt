import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal loginFinished(Context context)
    required property Wallet wallet
    property bool login: true
    function update() {
        if (stack_view.depth === 1 && devices_model.rowCount > 0) {
            stack_view.push(devices_view)
        } else if (stack_view.depth > 1 && devices_model.rowCount === 0) {
            stack_view.pop()
        }
    }
    Component.onCompleted: self.update()
    DeviceListModel {
        id: devices_model
        onRowCountChanged: self.update()
    }
    id: self
    title: self.wallet.name
    contentItem: GStackView {
        id: stack_view
        initialItem: ColumnLayout {
            VSpacer {
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                sourceComponent: {
                    switch (self.wallet.deviceDetails.type) {
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
                text: qsTrId('id_looking_for_device') + '  (' + self.wallet.deviceDetails.name + ')'
            }
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
            Loader {
                Layout.alignment: Qt.AlignCenter
                id: auto_login_loader
                active: device_repeater.count === 1 && device_repeater.itemAt(0)._device.connected
                sourceComponent: ColumnLayout {
                    LinkButton {
                        Layout.alignment: Qt.AlignCenter
                        text: 'Cancel Automatic Login'
                        onClicked: auto_login_loader.active = false
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
                                onFinished: device_repeater.itemAt(0).item.trigger()
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
                const device = delegate.device
                switch (device.state) {
                case JadeDevice.StateLocked:
                case JadeDevice.StateReady:
                    stack_view.push(jade_unlock_view, { device, showRemember: false })
                    break
                case JadeDevice.StateUninitialized:
                case JadeDevice.StateUnsaved:
                    // TODO: show view to jump to onboarding
                    break
                }
            }
            onSelected: delegate.trigger()
        }
    }
    Component {
        id: jade_unlock_view
        JadeUnlockView {
            context: wallet.context
            onUnlockFinished: (context) => {
                if (context.attachToWallet(self.wallet)) {
                    stack_view.push(jade_login_view, { context, device: context.device }, StackView.PushTransition)
                } else {
                    // TODO: show device mismatch view
                }
            }
            onUnlockFailed: stack_view.pop()
        }
    }

    Component {
        id: jade_login_view
        JadeLoginView {
            onLoginFinished: (context) => self.loginFinished(context)
        }
    }

    Component {
        id: jade_view
        JadeInstructionsView {
        }
    }
}
