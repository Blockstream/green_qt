import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "jade.js" as JadeJS

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
    objectName: "JadeVerifyAddressPage"
    id: self
    title: qsTrId('id_verify_on_device')
    footer: BusyIndicator {
        Layout.alignment: Qt.AlignCenter
        running: controller.addressVerification !== JadeVerifyAddressController.VerificationPending
    }
    contentItem: ColumnLayout {
        VSpacer {
        }

        AddressLabel {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            address: controller.address
            elide: AddressLabel.ElideNone
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            foreground: JadeJS.image(self.context.device, 7)
            width: 352
            height: 240
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.topMargin: 16
            font.pixelSize: 12
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
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
