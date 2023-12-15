import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Label {
    Layout.fillWidth: true
    Layout.preferredWidth: 0
    Layout.bottomMargin: 10
    Layout.topMargin: 10
    background: Rectangle {
        radius: 5
        color: Qt.alpha('#000', 0.1)
        border.width: 1
        border.color: Qt.alpha('#FFF', 0.1)
        Image {
            anchors.verticalCenter: parent.verticalCenter
            x: 20
            source: 'qrc:/svg2/info.svg'
        }
    }
    font.pixelSize: 14
    font.weight: 500
    leftPadding: 60
    rightPadding: 20
    bottomPadding: 20
    topPadding: 20
    wrapMode: Label.Wrap
}
