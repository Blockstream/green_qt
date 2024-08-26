import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    property alias spacing: layout.spacing
    default property alias contentItemData: layout.data
    ScrollBar.vertical: ScrollBar {
        policy: self.moving || self.contentHeight > self.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    }
    id: self
    clip: true
    contentWidth: self.width
    contentHeight: layout.height + 60
    ColumnLayout {
        id: layout
        spacing: 0
        width: self.width
        y: Math.max(0, (self.height - layout.height) / 2)
    }
}
