import QtQuick
import QtQuick.Controls

Label {
    id: self
    color: constants.c300
    property bool large: false
    property bool showTooltip: true
    text: self.text
    font.pixelSize: 10
    font.weight: 400
    font.styleName: 'Regular'
    padding: large ? 24 : 16
    topPadding: large ? 6 : 3
    bottomPadding: large ? 6 : 3
    background: Rectangle {
        id: rectangle
        radius: 4
        color: self.color
    }
    MouseArea {
        id: mouse_area
        anchors.fill: parent
        hoverEnabled: true
        enabled: self.showTooltip
    }
}
