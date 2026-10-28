import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractDrawer {
    signal genuine()
    signal diy()
    signal abort()
    required property bool autoCheck
    required property JadeDevice device
    onClosed: self.destroy()
    id: self
    edge: Qt.RightEdge
    minimumContentWidth: 400
    JadeGenuineCheckController {
        id: controller
        device: self.device
        onSuccess: stack_view.push(success_view)
        onNotGenuine: stack_view.replace(null, unsupported_page, StackView.PushTransition)
        onFailed: stack_view.replace(null, error_view, StackView.PushTransition)
        onUnsupported: stack_view.replace(null, unsupported_page, StackView.PushTransition)
        onCancelled: stack_view.replace(null, cancelled_view, StackView.PushTransition)
        onDisconnected: self.abort()
    }
    contentItem: GStackView {
        id: stack_view
        initialItem: {
            if (!self.device.secureBoot) return unsupported_page
            return self.autoCheck ? check_view : initial_view
        }
    }
    Component {
        id: initial_view
        JadeGenuineCheckPage {
            device: self.device
            leftItem: Item {}
            rightItem: CloseButton {
                onClicked: self.abort()
            }
            onStart: stack_view.replace(null, check_view, StackView.PushTransition)
            onClose: self.abort()
        }
    }

    Component {
        id: check_view
        JadeGenuineCheckingPage {
            device: self.device
            leftItem: Item {}
            rightItem: CloseButton {
                onClicked: self.abort()
            }
            StackView.onActivated: {
                controller.genuineCheck()
            }
        }
    }

    Component {
        id: cancelled_view
        JadeGenuineRetryPage {
            device: self.device
            heading: 'Genuine check canceled'
            message: 'We were unable to complete the authenticity check because it was canceled on Jade.'
            onCloseClicked: self.abort()
            onRetryClicked: stack_view.replace(null, check_view, StackView.PushTransition)
        }
    }

    Component {
        id: error_view
        JadeGenuineRetryPage {
            device: self.device
            heading: 'Unable to complete genuine check'
            message: 'Something went wrong while checking your Jade. This does not mean your device is not genuine, please try again.'
            onCloseClicked: self.abort()
            onRetryClicked: stack_view.replace(null, check_view, StackView.PushTransition)
        }
    }

    Component {
        id: unsupported_page
        JadeGenuineUnsupportedPage {
            device: self.device
            onCloseClicked: self.abort()
            onDiyClicked: self.diy()
        }
    }

    Component {
        id: success_view
        JadeGenuineSuccessPage {
            device: self.device
            onCloseClicked: self.genuine()
            onContinueClicked: self.genuine()
        }
    }
}

