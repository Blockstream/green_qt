import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    property int alignment: Qt.AlignCenter
    property alias spacing: layout.spacing
    default property alias contentItemData: layout.data
    // ScrollBar.vertical: ScrollBar {
    //     policy: self.moving || self.contentHeight > self.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    // }
    ScrollIndicator.vertical: ScrollIndicator {
    }
    id: self
    clip: true
    contentWidth: self.width
    contentHeight: layout.height + 60
    ColumnLayout {
        id: layout
        spacing: 0
        width: self.width
        y: {
            if (self.alignment == Qt.AlignCenter) {
                return Math.max(0, (self.height - layout.height) / 2)
            }
            return 0
        }
    }
}
