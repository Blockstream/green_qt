import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal genuine()
    signal diy()
    required property JadeDevice device
    id: self
    footer: null
    leftItem: Item {}
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    StackView.onActivated: controller.genuineCheck()
    JadeGenuineCheckController {
        id: controller
        device: self.device
        onSuccess: self.pushPage(success_page)
        onNotGenuine: self.pushPage(unsupported_page)
        onFailed: self.pushPage(error_page)
        onUnsupported: self.pushPage(unsupported_page)
        onCancelled: self.pushPage(cancelled_page)
        onDisconnected: self.closeClicked()
    }
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            foreground: 'qrc:/png/jade_genuine_2.png'
            width: 352
            height: 240
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: -10
            font.capitalization: Font.AllUppercase
            font.pixelSize: 16
            font.weight: 600
            text: self.device?.name ?? ''
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: 'Authenticate your Jade'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 0
            Layout.fillWidth: true
            Layout.maximumWidth: 400
            color: '#898989'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: 'Perform a genuine check to ensure that the Jade you received was manufactured by Blockstream.'
            wrapMode: Label.WordWrap
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 16
            font.weight: 600
            text: 'Confirm on your Jade'
        }
        VSpacer {
        }
    }

    Component {
        id: cancelled_page
        JadeGenuineRetryPage {
            device: self.device
            heading: 'Genuine check canceled'
            message: 'We were unable to complete the authenticity check because it was canceled on Jade.'
            onCloseClicked: self.closeClicked()
            onRetryClicked: self.popPage(self)
        }
    }

    Component {
        id: error_page
        JadeGenuineRetryPage {
            device: self.device
            heading: 'Unable to complete genuine check'
            message: 'Something went wrong while checking your Jade. This does not mean your device is not genuine, please try again.'
            onCloseClicked: self.closeClicked()
            onRetryClicked: self.popPage(self)
        }
    }

    Component {
        id: unsupported_page
        JadeGenuineUnsupportedPage {
            device: self.device
            onCloseClicked: self.closeClicked()
            onDiyClicked: self.diy()
        }
    }

    Component {
        id: success_page
        JadeGenuineSuccessPage {
            device: self.device
            onCloseClicked: self.genuine()
            onContinueClicked: self.genuine()
        }
    }
}
