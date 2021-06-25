import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

RadioButton {
    id: control
    property string description
    spacing: 16
    contentItem: ColumnLayout {
        spacing: 8
        Label {
            Layout.leftMargin: control.indicator.width + control.spacing
            Layout.fillWidth: true
            text: control.text
            font.pixelSize: 18
        }
        Label {
            Layout.leftMargin: control.indicator.width + control.spacing
            Layout.fillWidth: true
            text: description
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }
}
