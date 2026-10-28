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

    component RetryPage: StackViewPage {
        required property string heading
        required property string message
        id: page
        leftItem: Item {}
        rightItem: CloseButton {
            onClicked: self.abort()
        }
        contentItem: ColumnLayout {
            spacing: 20
            VSpacer {
            }
            MultiImage {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 260
                Layout.preferredWidth: 320
                foreground: 'qrc:/png/jade_genuine_1.png'
                margins: 30
                Image {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 40
                    source: 'qrc:/svg2/fail-light.svg'
                }
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
                text: page.heading
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
                text: page.message
                wrapMode: Label.WordWrap
            }
            RowLayout {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignCenter
                spacing: 10
                PrimaryButton {
                    Layout.minimumWidth: 160
                    text: qsTrId('Retry')
                    onClicked: stack_view.replace(null, check_view, StackView.PushTransition)
                }
            }
            VSpacer {
            }
        }
    }

    Component {
        id: cancelled_view
        RetryPage {
            heading: 'Genuine check canceled'
            message: 'We were unable to complete the authenticity check because it was canceled on Jade.'
        }
    }

    Component {
        id: error_view
        RetryPage {
            heading: 'Unable to complete genuine check'
            message: 'Something went wrong while checking your Jade. This does not mean your device is not genuine, please try again.'
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
        StackViewPage {
            leftItem: Item {}
            rightItem: CloseButton {
                onClicked: self.genuine()
            }
            contentItem: ColumnLayout {
                spacing: 20
                VSpacer {
                }
                Image {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: 260
                    Layout.preferredWidth: 320
                    source: 'qrc:/png/jade_genuine_1.png'
                }
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: -10
                    Label {
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: 16
                        font.weight: 600
                        text: self.device?.name ?? ''
                    }
                    Image {
                        id: seal_check
                        width: 24
                        height: 24
                        source: 'qrc:/svg2/seal-check.svg'
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 26
                    font.weight: 600
                    text: 'Your Jade is genuine!'
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    Layout.maximumWidth: 380
                    color: '#898989'
                    font.pixelSize: 14
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    text: 'We could successfully verify your jade, enjoy the best Blockstream can offer you with your brand new jade.'
                    wrapMode: Label.WordWrap
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.margins: 20
                    text: {
                        return self.device.state === JadeDevice.StateUninitialized
                            ? 'Continue Jade Setup'
                            : 'Continue with Jade'
                    }
                    onClicked: self.genuine()
                }
                VSpacer {
                }
            }
        }
    }
}

