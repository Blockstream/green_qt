import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Dialog {
    signal genuine()
    signal diy()
    signal skip()
    signal abort()
    required property bool autoCheck
    required property JadeDevice device
    function openSupport() {
        const version = Qt.application.version
        const url = `https://help.blockstream.com/hc/en-us/requests/new?tf_900008231623=${platform}&tf_subject=Genuine Check&&tf_900003758323=blockstream_jade&tf_900006375926=jade&tf_900009625166=${version}`
        Qt.openUrlExternally(url);
    }
    onClosed: self.destroy()
    id: self
    clip: true
    closePolicy: Popup.NoAutoClose
    modal: true
    anchors.centerIn: parent
    topPadding: 40
    bottomPadding: 40
    leftPadding: 40
    rightPadding: 40
    width: 600
    height: 600
    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.visible ? -0.05 : 0
        Behavior on brightness {
            NumberAnimation { duration: 200 }
        }
        blurEnabled: true
        blurMax: 64
        blur: self.visible ? 1 : 0
        Behavior on blur {
            NumberAnimation { duration: 200 }
        }
        source: ApplicationWindow.contentItem
    }
    background: Rectangle {
        color: '#13161D'
        radius: 10
        border.width: 1
        border.color: Qt.alpha('#FFFFFF', 0.07)
    }
    JadeGenuineCheckController {
        id: controller
        device: self.device
        onSuccess: stack_view.push(success_view)
        onFailed: self.skip()
        onUnsupported: stack_view.replace(null, diy_view, StackView.PushTransition)
        onCancelled: stack_view.replace(null, cancelled_view, StackView.PushTransition)
        onDisconnected: self.abort()
    }
    contentItem: GStackView {
        id: stack_view
        initialItem: self.autoCheck ? check_view : initial_view
    }
    Component {
        id: initial_view
        JadeGenuineCheckPage {
            device: self.device
            onStart: stack_view.replace(null, check_view, StackView.PushTransition)
            onClose: self.skip()
        }
    }

    Component {
        id: check_view
        JadeGenuineCheckingPage {
            StackView.onActivated: {
                controller.genuineCheck()
            }
        }
    }

    Component {
        id: cancelled_view
        ColumnLayout {
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
                font.pixelSize: 26
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: 'Genuine check canceled'
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
                text: 'We were unable to complete the authenticity check because it was canceled on Jade.'
                wrapMode: Label.WordWrap
            }
            RowLayout {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignCenter
                spacing: 10
                RegularButton {
                    Layout.minimumWidth: 160
                    text: qsTrId('id_skip')
                    onClicked: self.skip()
                }
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
        id: diy_view
        ColumnLayout {
            spacing: 20
            CloseButton {
                Layout.alignment: Qt.AlignRight
                onClicked: self.abort()
            }
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
                    source: 'qrc:/svg2/warning-light.svg'
                }
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 26
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: 'This Jade is not genuine'
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
                text: 'This device was not manufactured by Blockstream. It could be DIY hardware or possibly a malicious clone. Please contact support for more assistance.'
                wrapMode: Label.WordWrap
            }
            RowLayout {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignCenter
                spacing: 10
                PrimaryButton {
                    Layout.minimumWidth: 160
                    text: 'Contact Support'
                    onClicked: self.openSupport()
                }
                RegularButton {
                    Layout.minimumWidth: 160
                    text: 'Continue as DIY'
                    onClicked: self.diy()
                }
            }
            VSpacer {
            }
        }
    }

    Component {
        id: success_view
        ColumnLayout {
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
                    source: 'qrc:/svg2/check-light.svg'
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
