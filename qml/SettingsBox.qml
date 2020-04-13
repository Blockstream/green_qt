import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

GridLayout {
    id: box

    property string title
    property string description
    default property alias children: column_layout.children

    Layout.topMargin: 16
    columns: 2
    columnSpacing: 32

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: title
        color: 'gray'
        font.pixelSize : 18
        Layout.columnSpan: 2
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: description_label.implicitHeight
        implicitWidth: description_label.implicitWidth
        Label {
            id: description_label
            horizontalAlignment: Text.AlignJustify
            wrapMode: Label.WordWrap
            width: Math.min(parent.width, box.width * 2 / 3 - box.columnSpacing)
            text: description
            font.pixelSize: 15
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        id: column_layout
    }

    Rectangle {
        color: 'gray'
        opacity: 0.2
        implicitHeight: 1
        Layout.topMargin: 16
        Layout.columnSpan: 2
        Layout.fillWidth: true
    }
}
