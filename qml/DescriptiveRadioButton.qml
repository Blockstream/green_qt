import QtQuick 2.12
import QtQuick.Controls 2.5

RadioButton {
    id: control
    property string description
    spacing: 16
    contentItem: Column {
        leftPadding: control.indicator.width + control.spacing
        spacing: 8
        Label {
            text: control.text
            font.pixelSize: 18
        }
        Label {
            text: description
            font.pixelSize: 12
            width: 400
            wrapMode: Text.WordWrap
        }
    }
}
