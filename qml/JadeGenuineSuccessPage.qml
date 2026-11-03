import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal continueClicked()

    required property JadeDevice device

    id: self
    title: 'Genuine Check'
    skipOnPop: true
    rightItem: CloseButton {
        onClicked: self.closeClicked()
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
            onClicked: self.continueClicked()
        }
        VSpacer {
        }
    }
}
