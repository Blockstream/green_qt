import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GridLayout {
    property var mnemonic

    columnSpacing: 20
    rowSpacing: 16
    columns: 4
    rows: 6
    flow: GridLayout.LeftToRight

    Repeater {
        model: mnemonic
        RowLayout {
            spacing: 10
            Label {
                Layout.minimumWidth: 30
                text: `${index + 1}`
                textFormat: Text.RichText
                font.pixelSize : 14
                font.weight: 600
                horizontalAlignment: Label.AlignRight
            }
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 30
                id: word
                color: '#2FD058'
                text: modelData
                textFormat: Text.RichText
                font.pixelSize : 14
                font.weight: 600
            }
        }
    }
}
