import QtQuick 2.0
import QtQuick.Controls 2.13

Rectangle {
    color: Qt.rgba(1, 0, 0, 0.4)
    height: debug_column.height + 16
    width: debug_column.width + 16
    opacity: mouse_area.containsMouse ? 0.8 : 0.2

    MouseArea {
        id: mouse_area
        anchors.fill: parent
        hoverEnabled: true
    }

    Column {
        x: 8
        y: 8
        id: debug_column
        Label {
            font.pixelSize: 10
            text: ['FOCUS', activeFocusItem].join(' - ')
        }
    }
}
