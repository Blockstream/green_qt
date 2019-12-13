import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

Page {
    property string subtitle
    default property alias children: column_layout.children
    font.family: dinpro.name
    font.pixelSize: 15
    Layout.fillWidth: true
    header: Label {
        color: '#808080'
        font.capitalization: Font.AllUppercase
        text: title
    }

    background: Item {}

    RowLayout {
        anchors.fill: parent
        spacing: 30

        Label {
            Layout.alignment: Qt.AlignTop
            wrapMode: Text.WordWrap
            text: subtitle
            Layout.preferredWidth: 200
        }

        ColumnLayout {
            id: column_layout
        }
    }
}
