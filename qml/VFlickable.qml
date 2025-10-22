import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    property int alignment: Qt.AlignCenter
    property alias spacing: layout.spacing
    default property alias contentItemData: layout.data
    ScrollIndicator.vertical: ScrollIndicator {
    }
    id: self
    clip: true
    contentWidth: self.width
    contentHeight: layout.height
    ColumnLayout {
        id: layout
        spacing: 0
        width: self.width
        height: {
            if (self.alignment === Qt.AlignCenter) {
                return layout.implicitHeight
            }
            return Math.max(self.height, layout.implicitHeight)
        }
        y: {
            if (self.alignment === Qt.AlignCenter) {
                return Math.max(0, (self.height - layout.height) / 2)
            }
            return 0
        }
    }
}
