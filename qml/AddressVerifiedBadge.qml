import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    required property Address address
    Layout.alignment: Qt.AlignCenter
    Layout.topMargin: 15
    Layout.bottomMargin: 15
    id: self
    leftPadding: 14
    rightPadding: 14
    topPadding: 6
    bottomPadding: 6
    opacity: 0.8
    visible: self.address?.verified ?? false
    background: Rectangle {
        border.width: 1
        border.color: '#FFF'
        color: 'transparent'
        radius: height / 2
    }
    contentItem: RowLayout {
        Image {
            source: 'qrc:/svg2/seal-check.svg'
        }
        Label {
            font.capitalization: Font.AllUppercase
            font.pixelSize: 14
            font.weight: 600
            text: qsTrId('id_verified')
        }
    }
}
