import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal diyClicked()

    required property JadeDevice device
    readonly property bool diy: !self.device.secureBoot

    function openSupport() {
        const version = Qt.application.version
        const url = `https://help.blockstream.com/hc/en-us/requests/new?tf_900008231623=${platform}&tf_subject=Genuine Check&&tf_900003758323=blockstream_jade&tf_900006375926=jade&tf_900009625166=${version}`
        Qt.openUrlExternally(url);
    }

    id: self
    title: 'Genuine Check'
    leftItem: Item {}
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
            text: self.diy
                ? 'This device was not manufactured by Blockstream. It could be DIY hardware or possibly a malicious clone. Please contact support for more assistance.'
                : 'This device was not manufactured by Blockstream and could be a malicious clone. Please contact support for more assistance.'
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
                visible: self.diy
                onClicked: self.diyClicked()
            }
        }
        VSpacer {
        }
    }
}
