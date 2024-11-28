import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    footer: null
    header: null
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
}
