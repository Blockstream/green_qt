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
            mismatch_banner.title = 'This Jade does not hold ' + self.wallet.name
            return
        }
        mismatch_banner.title = ''
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
            onClicked: Qt.openUrlExternally('https://help.blockstream.com/blockstream-jade/troubleshooting/fix-issues-connecting-jade-via-usb-or-bluetooth')
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
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 10
        BluetoothPermissionWarning {
        }
        UiAlertBanner {
            Layout.fillWidth: true
            id: mismatch_banner
            dismissible: true
            variant: UiAlertBanner.Negative
            visible: mismatch_banner.title.length > 0
            onDismissed: mismatch_banner.title = ''
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
