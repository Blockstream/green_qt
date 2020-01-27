import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

GridLayout {
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

    Label {
        Layout.fillWidth: true
        wrapMode: Label.WordWrap
        text: description
        font.pixelSize: 15
    }

    ColumnLayout {
        id: column_layout
        //Layout.alignment: Qt.AlignTop
    }
}
