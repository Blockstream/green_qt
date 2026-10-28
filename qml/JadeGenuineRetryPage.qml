import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal retryClicked()

    required property JadeDevice device
    required property string heading
    required property string message

    id: self
    leftItem: Item {}
    rightItem: CloseButton {
        onClicked: self.closeClicked()
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
            text: self.heading
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
            text: self.message
            wrapMode: Label.WordWrap
        }
        RowLayout {
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignCenter
            spacing: 10
            PrimaryButton {
                Layout.minimumWidth: 160
                text: qsTrId('Retry')
                onClicked: self.retryClicked()
            }
        }
        VSpacer {
        }
    }
}
