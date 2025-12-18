import QtQuick

Collapsible {
    property real leftPadding: 0
    property bool black: false
    required property bool active
    id: indicator
    collapsed: !indicator.active
    contentWidth: indicator.leftPadding + image.width
    horizontalCollapse: true
    verticalCollapse: false
    Image {
        id: image
        source: indicator.black ? 'qrc:/svg2/right-black.svg' : 'qrc:/svg2/right.svg'
        x: indicator.leftPadding
    }
}
