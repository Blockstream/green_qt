import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

GridLayout {
    property var mnemonic

    columnSpacing: 10
    rowSpacing: 30
    columns: 4
    rows: 6
    flow: GridLayout.TopToBottom

    Repeater {
        model: mnemonic
        RowLayout {
            Label {
                Layout.minimumWidth: 24
                text: `${index + 1}`
                textFormat: Text.RichText
                font.pixelSize : 16
                color: '#2FD058'
                horizontalAlignment: Label.AlignRight
            }
            Label {
                Layout.fillWidth: true
                id: word
                text: modelData
                textFormat: Text.RichText
                font.pixelSize : 16
                rightPadding: 24
            }
        }
    }
}
