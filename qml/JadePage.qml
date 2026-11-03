import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal loginFinished(Context context)
    signal skip(Device device)
    signal detailsClicked()
    required property JadeDevice device
    // The context the device was unlocked on, if any, to log in with.
    property Context context: null
    // Set when the user picked the device, otherwise wait for Login.
    property bool unlock: false
    readonly property bool ready: (self.device?.connected && 'BOARD_TYPE' in self.device?.versionInfo)
    ErrorNotification {
        id: error_notification
    }
    readonly property var notifications: UtilJS.flatten(error_notification)
    id: self
    footer: null
    padding: 60
    title: self.device.name
    rightItem: RowLayout {
        Layout.topMargin: 20
        spacing: 20
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_setup_guide')
            visible: self.device.state === JadeDevice.StateUninitialized
            external: true
            onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/19629901272345-Set-up-Jade')
        }
        CircleButton {
            icon.source: 'qrc:/svg2/info.svg'
            visible: Qt.application.arguments.includes('--debugjade')
            onClicked: self.detailsClicked()
        }
        WalletOptionsButton {
            wallet: null
            onCloseClicked: self.closeClicked()
        }
    }
    function pushView() {
        if (stack_view.depth > 0) return
        if (!self.ready) return
        self.showState()
    }

    function showState() {
        error_notification.dismiss()
        switch (self.device.state) {
        case JadeDevice.StateReady:
            stack_view.replace(null, login_view, { context: self.context, device: self.device }, StackView.PushTransition)
            break;
        case JadeDevice.StateTemporary:
        case JadeDevice.StateLocked:
            if (self.unlock) {
                stack_view.replace(null, unlock_view, { device: self.device }, StackView.PushTransition)
            } else {
                stack_view.replace(null, intialized_view, StackView.PushTransition)
            }
            break
        case JadeDevice.StateUninitialized:
        case JadeDevice.StateUnsaved:
            stack_view.replace(null, unintialized_view, StackView.PushTransition)
            break
        }
        console.log('nothing to show, jade state is', self.device.state)
    }

    Connections {
        target: self.device
        function onConnectionSelectedChanged() {
            // The selected link went away, ask again before going on.
            if (self.device.connectionSelected || !self.device.bluetoothAvailable) return
            stack_view.clear()
            self.pushView()
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: self.pushView()
    }

    contentItem: Item {
        BusyIndicator {
            anchors.centerIn: parent
            running: stack_view.depth === 0
            visible: stack_view.depth === 0
        }
        GStackView {
            anchors.fill: parent
            anchors.leftMargin: self.padding
            anchors.rightMargin: self.padding
            anchors.bottomMargin: self.padding
            id: stack_view
        }
    }

    Component {
        id: unlock_view
        JadeUnlockView {
            context: null
            showRemember: true
            onUnlockFinished: (context) => stack_view.replace(null, login_view, { context, device: self.device }, StackView.PushTransition)
            onUnlockFailed: stack_view.replace(null, intialized_view, StackView.PushTransition)
        }
    }

    Component {
        id: intialized_view
        JadeInitializedView {
            device: self.device
            onLoginClicked: {
                if (self.device.state === JadeDevice.StateLocked || self.device.state === JadeDevice.StateTemporary) {
                    stack_view.replace(null, unlock_view, { device: self.device }, StackView.PushTransition)
                } else {
                    self.showState()
                }
            }
        }
    }

    Component {
        id: login_view
        JadeLoginView {
            onLoginFinished: (context) => self.loginFinished(context)
            onLoginFailed: self.loginFinished(context)
        }
    }

    Component {
        id: unintialized_view
        JadeUninitializedView {
            device: self.device
            onSetupFinished: (context) => stack_view.clear()
        }
    }
}
