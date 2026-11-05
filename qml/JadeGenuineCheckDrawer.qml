import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

AbstractDrawer {
    signal genuine()
    signal diy()
    signal abort()
    required property bool autoCheck
    property JadeDevice device: null
    // Without a device, one is picked and unlocked on this context.
    property Context context: null
    function startPage() {
        if (!self.device.secureBoot) return unsupported_page
        return self.autoCheck ? checking_page : check_page
    }
    onClosed: self.destroy()
    id: self
    edge: Qt.RightEdge
    minimumContentWidth: 400
    contentItem: GStackView {
        id: stack_view
        initialItem: self.device ? self.startPage() : connect_page
    }
    Component {
        id: connect_page
        ConnectJadePage {
            context: self.context
            wallet: self.context?.wallet ?? null
            onDeviceSelected: (device) => {
                self.device = device
                stack_view.replace(null, self.startPage(), StackView.PushTransition)
            }
            onCloseClicked: self.abort()
        }
    }

    Component {
        id: check_page
        JadeGenuineCheckPage {
            device: self.device
            leftItem: Item {}
            onCloseClicked: self.abort()
            onStart: stack_view.replace(null, checking_page, StackView.PushTransition)
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

