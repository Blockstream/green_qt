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
    contentItem: GStackView {
        id: stack_view
        initialItem: {
            if (!self.device.secureBoot) return unsupported_page
            return self.autoCheck ? checking_page : check_page
        }
    }
    Component {
        id: check_page
        JadeGenuineCheckPage {
            device: self.device
            leftItem: Item {}
            rightItem: CloseButton {
                onClicked: self.abort()
            }
            onStart: stack_view.replace(null, checking_page, StackView.PushTransition)
            onClose: self.abort()
        }
    }

    Component {
        id: checking_page
        JadeGenuineCheckingPage {
            device: self.device
            onCloseClicked: self.abort()
            onGenuine: self.genuine()
            onDiy: self.diy()
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
}

