import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    signal unlockFinished(Context context)
    signal unlockFailed()
    required property JadeDevice device
    StackView.onActivated: controller.unlock()
    id: self
    spacing: 20
    JadeUnlockController {
        id: controller
        device: self.device
        onUnlocked: (context) => self.unlockFinished(context)
        onInvalidPin: self.unlockFailed()
    }
    VSpacer {
    }
    Image {
        Layout.alignment: Qt.AlignCenter
        source: 'qrc:/png/connect_jade_2.png'
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
}
