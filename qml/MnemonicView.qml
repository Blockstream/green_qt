import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GridLayout {
    property var mnemonic

    columnSpacing: 40
    rowSpacing: 20
    columns: 4
    rows: 6
    flow: GridLayout.TopToBottom

    Repeater {
        model: mnemonic
        RowLayout {
            spacing: 10
            Label {
                Layout.minimumWidth: 30
                text: `${index + 1}`
                textFormat: Text.RichText
                font.pixelSize : 16
                font.weight: 600
                color: '#2FD058'
                horizontalAlignment: Label.AlignRight
            }
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 30
                id: word
                text: modelData
                textFormat: Text.RichText
                font.pixelSize : 16
                font.weight: 600
            }
        }
    }
}
