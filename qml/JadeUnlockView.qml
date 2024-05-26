import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    signal unlockFinished(Context context)
    signal unlockFailed()
    required property Context context
    required property JadeDevice device
    property bool showRemember: true
    StackView.onActivated: controller.unlock()
    id: self
    spacing: 20
    JadeUnlockController {
        id: controller
        context: self.context
        device: self.device
        onHttpRequest: (request) => {
            const dialog = http_request_dialog.createObject(self, { request, context: self.context })
            dialog.open()
        }
        onUnlocked: (context) => self.unlockFinished(context)
        onInvalidPin: self.unlockFailed()
        onDisconnected: self.unlockFailed()
    }
    VSpacer {
    }
    MultiImage {
        Layout.alignment: Qt.AlignCenter
        width: 352
        height: 240
        foreground: 'qrc:/png/jade_7.png'
    }
    Label {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        color: '#FFFFFF'
        font.pixelSize: 22
        font.weight: 600
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_unlock_your_device_to_continue')
        wrapMode: Label.WordWrap
    }
    VSpacer {
    }
    Component {
        id: http_request_dialog
        JadeHttpRequestDialog {
        }
    }
}
