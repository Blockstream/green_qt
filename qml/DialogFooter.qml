import QtQuick
import QtQuick.Layouts

GPane {
    default property alias contentItemData: row_layout.data
    leftPadding: 24
    rightPadding: 24
    bottomPadding: 24
    topPadding: 0
    contentItem: RowLayout {
        id: row_layout
        spacing: 12
    }
}
