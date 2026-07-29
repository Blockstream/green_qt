import QtQuick

CircleButton {
    signal shared()

    required property url url
    id: self
    icon.source: 'qrc:/svg2/share.svg'
    onClicked: {
        Qt.openUrlExternally(self.url)
        self.shared()
    }
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
