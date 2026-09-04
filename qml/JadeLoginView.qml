import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

LoggingInPage {
    signal loginFinished(Context context)
    signal loginFailed()
    required property Context context
    required property Device device
    property bool loginSubmitted: false
    StackView.onActivated: {
        if (self.loginSubmitted) return
        self.loginSubmitted = true
        controller.loginWithDevice(self.device)
    }
    id: self
    header: null
    padding: 0
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
}
