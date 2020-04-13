import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

Page {

    default property alias children: column_layout.children;
    property alias icon: icon_image.source

    header: Pane {
        RowLayout {
            Image {
                id: icon_image
                sourceSize.width: 32
                sourceSize.height: 32
            }
            Label {
                id: title_label
                text: title
            }
        }
    }

    ColumnLayout {
        id: column_layout
        anchors.fill: parent
    }
}
