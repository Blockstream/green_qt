import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

Page {
    default property alias children: column.children;

    header: Label {
        padding: 16
        opacity: 0.4
        text: title
    }

    background: Item {
    }

    Column {
        id: column
        anchors.fill: parent
    }
}
