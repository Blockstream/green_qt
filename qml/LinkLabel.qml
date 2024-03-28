import QtQuick
import QtQuick.Controls

Label {
    id: self
    textFormat: Text.RichText
    onLinkActivated: (link) => { Qt.openUrlExternally(link) }
    HoverHandler {
        enabled: self.hoveredLink
        cursorShape: Qt.PointingHandCursor
    }
}
