import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

Page {
    property string description
    default property alias children: column_layout.children
    font.family: dinpro.name
    font.pixelSize: 15
    Layout.fillWidth: true
    background: Item {}

    RowLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 15

            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: title
                font.pixelSize : 18
            }

            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                wrapMode: Label.WordWrap
                text: description
            }
        }

        ColumnLayout {
            id: column_layout
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }
    }
}
