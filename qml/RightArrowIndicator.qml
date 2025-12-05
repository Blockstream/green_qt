import QtQuick

Collapsible {
    required property bool active
    id: indicator
    collapsed: !indicator.active
    horizontalCollapse: true
    verticalCollapse: false
    Image {
        source: 'qrc:/svg2/right.svg'
    }
}
