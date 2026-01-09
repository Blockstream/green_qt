import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
    id: self
    leftPadding: 0
    rightPadding: 0
    topPadding: 8
    bottomPadding: 8
    text: qsTrId('id_back')
    background: Item {
        Rectangle {
            border.width: 2
            border.color: '#00BCFF'
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
            color: '#FFFFFF'
            font.pixelSize: 14
            font.weight: 600
            text: self.text
        }
    }
}
