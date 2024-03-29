import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RadioButton {
    id: control
    property string description
    property var tags: []
    spacing: 16
    contentItem: ColumnLayout {
        spacing: 8
        RowLayout {
            spacing: constants.s1
            Label {
                Layout.leftMargin: control.indicator.width + control.spacing
                Layout.maximumWidth: implicitWidth + 1
                Layout.fillWidth: true
                text: control.text
                font.pixelSize: 18
            }
            Repeater {
                model: control.tags
                Label {
                    padding: 4
                    leftPadding: 8
                    rightPadding: 8
                    background: Rectangle {
                        border.color: modelData.color
                        border.width: 1
                        color: 'transparent'
                        radius: height / 2
                    }
                    text: modelData.text
                    font.pixelSize: 10
                    font.weight: 400
                    font.styleName: 'Regular'
                    font.capitalization: Font.AllUppercase
                    color: modelData.color
                }
            }
            HSpacer {}
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
