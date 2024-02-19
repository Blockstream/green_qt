import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property JadeDevice device
    required property ReceiveAddressController controller
    function update() {
        switch (self.device.state) {
        case JadeDevice.StateReady:
            controller.verify()
            break
        case JadeDevice.StateTemporary:
        case JadeDevice.StateLocked:
            self.StackView.view.push(unlock_view, { context: controller.context, device: self.device })
            break
        }
    }

    StackView.onActivated: self.update()
    id: self
    Timer {
        running: controller.addressVerification === ReceiveAddressController.VerificationAccepted
        interval: 1000
        onTriggered: self.StackView.view.pop()
    }
    Timer {
        running: controller.addressVerification === ReceiveAddressController.VerificationRejected
        interval: 1000
        onTriggered: self.StackView.view.pop()
    }
    title: qsTrId('id_verify_on_device')
    footer: BusyIndicator {
        Layout.alignment: Qt.AlignCenter
        running: controller.addressVerification !== ReceiveAddressController.VerificationPending
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 14
            font.weight: 500
            horizontalAlignment: Label.AlignHCenter
            text: controller.address.address
            wrapMode: Label.Wrap
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            foreground: 'qrc:/png/jade_7.png'
            width: 352
            height: 240
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 12
            font.weight: 500
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_please_verify_that_this_address')
            wrapMode: Label.WordWrap
        }
        VSpacer {
        }
    }

    Component {
        id: unlock_view
        JadeUnlockView {
            showRemember: false
            onUnlockFinished: {
                self.StackView.view.pop()
                self.update()
            }
            onUnlockFailed: {
                self.StackView.view.pop()
                self.StackView.view.pop()
            }
        }
    }
}
