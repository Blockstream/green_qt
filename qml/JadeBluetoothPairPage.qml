import Blockstream.Controls
import Blockstream.Green
import Blockstream.Green.Core
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal deviceSelected(JadeDevice device)
    required property JadeDevice device
    property bool started: false
    property bool confirmed: false
    readonly property bool confirming: self.device.bluetoothState === JadeDevice.BluetoothConfirmingPin
    // Only while on top: once handed off, later link changes are not this page's.
    function check() {
        if (self.StackView.status !== StackView.Active) return
        if (self.device.connected && self.device.bluetoothAvailable) {
            self.device.selectConnection(JadeDevice.Bluetooth)
            self.deviceSelected(self.device)
        }
    }
    // Going back or closing the drawer abandons a bond still in progress.
    Component.onDestruction: {
        const state = self.device?.bluetoothState
        if (state === JadeDevice.BluetoothPairing || state === JadeDevice.BluetoothConfirmingPin) self.device.cancelBluetoothPairing()
    }
    StackView.onActivated: {
        if (self.device.bluetoothState === JadeDevice.BluetoothUnpaired) self.device.pairBluetooth()
        self.check()
    }
    Connections {
        target: self.device
        function onConnectedChanged() {
            self.check()
        }
        function onBackendsChanged() {
            self.check()
        }
        function onBluetoothStateChanged() {
            const state = self.device.bluetoothState
            self.confirmed = false
            if (state === JadeDevice.BluetoothUnpaired || state === JadeDevice.BluetoothNone) {
                if (self.started && self.StackView.status === StackView.Active) self.StackView.view.pop()
            } else {
                self.started = true
            }
        }
    }
    id: self
    skipOnPop: true
    title: qsTrId('id_connecting_to_your_device')
    contentItem: ColumnLayout {
        spacing: 20
        VSpacer {
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            visible: !self.confirming
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            color: '#FFF'
            font.pixelSize: 14
            font.weight: 600
            opacity: 0.6
            text: qsTrId('id_connecting')
            visible: !self.confirming
        }
        UiLabel {
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: 300
            typography: Theme.typography.bodyS
            color: Theme.colors.textSubtle
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: 'Make sure this code matches the one on Jade, then confirm on both devices.'
            visible: self.confirming
        }
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 300
            implicitHeight: 56
            color: Theme.colors.surfaceSunken
            border.color: Theme.colors.borderSubtle
            border.width: 1
            radius: 4
            visible: self.confirming
            UiLabel {
                anchors.centerIn: parent
                typography: Theme.typography.titleLSemibold
                color: Theme.colors.textPrimary
                text: self.device.bluetoothPin.replace(/(\d{3})(?=\d)/g, '$1 ')
            }
        }
        UiButton {
            Layout.alignment: Qt.AlignCenter
            text: 'Code matches'
            busy: self.confirmed
            visible: self.confirming
            onClicked: {
                self.confirmed = true
                self.device.confirmBluetoothPin(true)
            }
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_cancel')
            visible: self.confirming
            onClicked: self.device.confirmBluetoothPin(false)
        }
        VSpacer {
        }
    }
}
