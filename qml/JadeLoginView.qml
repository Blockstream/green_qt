import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

VFlickable {
    signal loginFinished(Context context)
    signal loginFailed()
    required property Context context
    required property Device device
    StackView.onActivated: controller.loginWithDevice(self.device)
    id: self
    spacing: 20
    LoginController {
        id: controller
        context: self.context
        onLoginFinished: (context) => self.loginFinished(context)
        onLoginFailed: self.loginFailed()
    }
    TaskPageFactory {
        title: self.title ?? ''
        monitor: controller.monitor
        target: self.StackView.view
    }
    BusyIndicator {
        Layout.alignment: Qt.AlignCenter
    }
    Label {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        color: '#FFFFFF'
        font.pixelSize: 22
        font.weight: 600
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_logging_in')
        wrapMode: Label.WordWrap
    }
}
