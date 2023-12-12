import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    signal loginFinished(Context context)
    signal updateClicked()
    required property JadeDevice device
    id: self
    enabled: self.device.status === JadeDevice.StatusIdle
    spacing: 10
    DeviceController {
        id: controller
        device: self.device
        onBinded: (context) => self.loginFinished(context)
    }
    VSpacer {
    }
    Image {
        Layout.alignment: Qt.AlignCenter
        source: 'qrc:/png/onboard_jade_1.png'
    }
    PrimaryButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        text: qsTrId('id_login')
        onClicked: {
            if (self.device.state === JadeDevice.StateLocked) {
                self.StackView.view.push(unlock_view)
            } else if (self.device.state === JadeDevice.StateReady) {
                controller.bind()
            }
        }
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        enabled: self.device.status === JadeDevice.StatusIdle
        text: qsTrId('id_firmware_update')
        onClicked: self.updateClicked()
    }
    CheckBox {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 10
        id: remember_checkbox
        checked: true
        text: qsTrId('id_remember_device_connection')
        leftPadding: 12
        rightPadding: 12
        topPadding: 8
        bottomPadding: 8
        background: Rectangle {
            color: '#282D38'
            border.width: 1
            border.color: '#FFF'
            radius: 5
        }
    }
    VSpacer {
    }

    Component {
        id: unlock_view
        JadeUnlockView {
            context: null
            device: self.device
            onUnlockFinished: (context) => self.loginFinished(context)
            onUnlockFailed: self.StackView.view.pop()
        }
    }
}
