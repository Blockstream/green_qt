import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

GridLayout {
    property var mnemonic

    columnSpacing: 24
    rowSpacing: 24
    columns: 6
    flow: GridLayout.LeftToRight

    Repeater {
        model: mnemonic
        RowLayout {
            Label {
                Layout.minimumWidth: 24
                text: `${index + 1}`
                textFormat: Text.RichText
                font.pixelSize : 12
                color: Material.accentColor
                horizontalAlignment: Label.AlignRight
            }
            Label {
                Layout.fillWidth: true
                id: word
                text: modelData
                textFormat: Text.RichText
                font.pixelSize : 15
            }
        }
    }
}
