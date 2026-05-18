import QtQuick

CircleButton {
    required property url url
    id: self
    icon.source: 'qrc:/svg2/share.svg'
    onClicked: Qt.openUrlExternally(self.url)
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
