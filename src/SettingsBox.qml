import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

Page {
    property alias subtitle: subtitle_label.text
    default property alias children: column_layout.children
    font.family: dinpro.name
    font.pixelSize: 15

    header: Label {
        color: '#808080'
        font.capitalization: Font.AllUppercase
        text: title
    }

    background: Item {}

    RowLayout {
        spacing: 30

        Label {
            Layout.alignment: Qt.AlignTop
            id: subtitle_label
            wrapMode: Text.WordWrap
            text: subtitle
            Layout.preferredWidth: 300
        }

        ColumnLayout {
            id: column_layout
        }
    }
}
