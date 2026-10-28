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

