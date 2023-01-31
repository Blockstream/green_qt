import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    default property alias contentItemData: row_layout.data
    Layout.fillWidth: true
    padding: 0
    contentItem: RowLayout {
        spacing: 0
        Item {
            Layout.minimumHeight: 44
            width: 0
        }
        RowLayout {
            id: row_layout
            spacing: constants.s1
        }
    }
}
