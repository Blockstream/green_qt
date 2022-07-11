import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

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
