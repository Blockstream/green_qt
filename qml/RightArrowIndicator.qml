import QtQuick

Collapsible {
    property real leftPadding: 0
    required property bool active
    id: indicator
    collapsed: !indicator.active
    contentWidth: indicator.leftPadding + image.width
    horizontalCollapse: true
    verticalCollapse: false
    Image {
        id: image
        source: 'qrc:/svg2/right.svg'
        x: indicator.leftPadding
    }
}
