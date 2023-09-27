import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: self
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    background: Item {
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            opacity: self.visualFocus ? 1 : 0
        }
    }
    contentItem: RowLayout {
        spacing: 5
        Image {
            source: 'qrc:/svg2/back.svg'
        }
        Label {
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 600
            text: qsTrId('id_back')
        }
    }
}
