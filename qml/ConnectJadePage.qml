import Blockstream.Controls
import Blockstream.Green
import Blockstream.Green.Core
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal deviceSelected(JadeDevice device, Context context)
    signal loginFinished(Context context)
    // When set, only a device holding this wallet is accepted.
    property Wallet wallet: null
    // When set, the device is unlocked on this context instead of a new one.
    property Context context: null
    property bool qrEnabled: false

    function selectDevice(device, context) {
        if (self.wallet && device.session?.xpubHashId !== self.wallet.xpubHashId) {
            self.StackView.view.pop(self)
            mismatch_badge.raise('This Jade does not hold ' + self.wallet.name)
            return
        }
        mismatch_badge.clear()
        self.deviceSelected(device, context)
    }

    id: self
    title: 'Select device and connection'
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: ColumnLayout {
        RegularButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 360
            Layout.topMargin: 40
            visible: self.qrEnabled
            cyan: true
            text: qsTrId('id_connect_via_qr') + ' (Plus & Classic only)'
            onClicked: {
                self.StackView.view.push(jade_qr_connect_page)
            }
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            Layout.bottomMargin: 20
            external: true
            text: qsTrId('id_troubleshoot')
            onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900005443223-Fix-issues-connecting-Jade-via-USB')
        }
    }
    DeviceDiscoveryRequest {
    }
    JadeConnectFlow {
        id: flow
        page: self
        context: self.context
        onDeviceReady: (device, context) => self.selectDevice(device, context)
        onCloseClicked: self.closeClicked()
    }
    contentItem: ColumnLayout {
        BluetoothPermissionWarning {
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignCenter
            id: mismatch_badge
            pointer: false
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 10
            visible: device_repeater.count > 0
            Repeater {
                id: device_repeater
                model: DeviceListModel {
                    type: Device.BlockstreamJade
                }
                delegate: JadeDeviceDelegate {
                    Layout.fillWidth: true
                    onConnectUsbClicked: (device) => flow.connectUsb(device)
                    onConnectBluetoothClicked: (device) => flow.connectBluetooth(device)
                }
            }
        }
        VSpacer {
            visible: device_repeater.count === 0
        }
        JadeInstructionsView {
            visible: device_repeater.count === 0
        }

        UiCard {
            Layout.fillWidth: true
            variant: UiCard.Secondary
            contentItem: RowLayout {
                HSpacer {}
                BusyIndicator {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                }
                Label {
                    color: '#FFF'
                    font.pixelSize: 12
                    font.weight: 600
                    opacity: 0.6
                    text: qsTrId('id_looking_for_device')
                }
                HSpacer {}
            }
        }
        VSpacer {
        }
    }

    Component {
        id: jade_qr_connect_page
        JadeQrConnectPage {
            onLoginFinished: (context) => self.loginFinished(context)
        }
    }
}
