import QtQuick
import QtQuick.Controls

Label {
    id: self
    color: '#68727D'
    property bool large: false
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
}
