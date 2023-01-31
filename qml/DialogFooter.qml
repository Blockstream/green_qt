import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    default property alias contentItemData: row_layout.data
    leftPadding: constants.p3
    rightPadding: constants.p3
    bottomPadding: constants.p3
    topPadding: 0
    contentItem: RowLayout {
        id: row_layout
        spacing: constants.s1
    }
}
