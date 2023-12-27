import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal loginFinished(Context context)
    signal loginFailed()
    required property LedgerDevice device
    required property bool remember
    function pushView() {
        if (stack_view.depth > 0) return
        if (!self.device.compatible) return
        self.pushStateView()
    }
    function pushStateView() {
        stack_view.push(login_view, { context: null, remember: self.remember, device: self.device })
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
