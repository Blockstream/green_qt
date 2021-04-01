import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Pane {
    default property alias contentItemData: row_layout.data
    background: null
    leftPadding: constants.p3
    rightPadding: constants.p3
    topPadding: constants.p3
    bottomPadding: constants.p0
    contentItem: RowLayout {
        id: row_layout
        spacing: constants.s1
    }
}
