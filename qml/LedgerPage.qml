import Blockstream.Green
import QtQuick

StackViewPage {
    signal loginFinished(Context context)
    signal loginFailed()
    required property LedgerDevice device
    function pushView() {
        if (stack_view.depth > 0) return
        if (!self.device.compatible) return
        self.pushStateView()
    }
    function pushStateView() {
        stack_view.push(login_view, { context: null, device: self.device })
    }
    Component.onCompleted: pushView()
    id: self
    padding: 60
    footer: null
    title: self.device.name
    contentItem: GStackView {
        id: stack_view
    }
    Component {
        id: login_view
        JadeLoginView {
            onLoginFinished: (context) => self.loginFinished(context)
            onLoginFailed: self.loginFailed()
        }
    }
}
