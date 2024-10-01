import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property Address address
    function update() {
        switch (self.context.device.state) {
        case JadeDevice.StateReady:
            controller.verify()
            break
        case JadeDevice.StateTemporary:
        case JadeDevice.StateLocked:
            self.StackView.view.push(unlock_view, { context: self.context, device: self.context.device })
            break
        }
    }
    JadeVerifyAddressController {
        id: controller
        context: self.context
        address: self.address
    }
    Timer {
        running: controller.addressVerification === JadeVerifyAddressController.VerificationAccepted
        interval: 1000
        onTriggered: self.StackView.view.pop()
    }
    Timer {
        running: controller.addressVerification === JadeVerifyAddressController.VerificationRejected
        interval: 1000
        onTriggered: self.StackView.view.pop()
    }
    StackView.onActivated: self.update()
    id: self
    title: qsTrId('id_verify_on_device')
    footer: BusyIndicator {
        Layout.alignment: Qt.AlignCenter
        running: controller.addressVerification !== JadeVerifyAddressController.VerificationPending
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.features: { 'calt': 0, 'zero': 1 }
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
