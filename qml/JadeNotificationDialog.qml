import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects

Dialog {
    signal setupClicked(JadeDevice device)
    required property JadeDevice device
    Overlay.modal: Rectangle {
        id: modal
        color: constants.c900
        FastBlur {
            anchors.fill: parent
            cached: true
            opacity: 0.5
            radius: 64
            source: ShaderEffectSource {
                sourceItem: ApplicationWindow.contentItem
                sourceRect {
                    x: 0
                    y: 0
                    width: modal.width
                    height: modal.height
                }
            }
        }
    }
    id: self
    anchors.centerIn: parent
    closePolicy: Dialog.NoAutoClose
    topPadding: 60
    bottomPadding: 60
    leftPadding: 60
    rightPadding: 60
    background: Rectangle {
        color: '#13161D'
        radius: 10
        border.width: 1
        border.color: Qt.alpha('#FFFFFF', 0.07)
    }
    contentItem: ColumnLayout {
        spacing: 20
        Label {
            Layout.alignment: Qt.AlignCenter
            font.family: 'SF Compact Display'
            font.pixelSize: 26
            font.weight: 600
            text: 'Hardware Wallet Connected'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 600
            opacity: 0.4
            text: 'We have detected a hardware device that is not yet setup. '
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/png/onboard_jade_1.png'
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            text: 'Setup Jade'
            onClicked: self.setupClicked(self.device)
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            text: 'Not now'
            onClicked: self.close()
        }
    }
}
