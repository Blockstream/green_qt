import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal start(JadeDevice device)
    required property JadeDevice device
    id: self
    title: 'Genuine Check'
    footer: null
    skipOnPop: true
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: {
                if (self.device.versionInfo.BOARD_TYPE === 'JADE_V2') {
                    return 'New Jade Plus Connected'
                }
                if (self.device.versionInfo.BOARD_TYPE === 'JADE_V2C') {
                    return 'New Jade Core Connected'
                }
                return 'New Jade Connected'
            }
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 0
            Layout.fillWidth: true
            color: '#898989'
            font.pixelSize: 14
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: 'A new device has been detected, please set it up to start using it.'
            wrapMode: Label.WordWrap
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 260
            Layout.preferredWidth: 320
            foreground: 'qrc:/png/jade_genuine_1.png'
            margins: 30
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.margins: 20
            enabled: self.device.status === JadeDevice.StatusIdle
            text: 'Genuine Check'
            onClicked: self.start(self.device)
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 0
            Layout.fillWidth: true
            color: '#898989'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: 'Genuine Check is mandatory for first time Jade connection. This way we make sure that you have a safe Jade.'
            wrapMode: Label.WordWrap
        }
        VSpacer {
        }
    }
}
