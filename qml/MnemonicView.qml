import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

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
