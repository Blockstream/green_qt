import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

GridLayout {
    property var mnemonic

    columns: 6
    flow: GridLayout.LeftToRight

    Repeater {
        model: mnemonic

        Item {
            width: 80
            height: 25

            Row {
                spacing: 5

                Label {
                    text: `${index + 1}`
                    textFormat: Text.RichText
                    font.pixelSize : 12
                    color: Material.accentColor
                    anchors.baseline: word.baseline
                    horizontalAlignment: Label.AlignRight
                    width: 10
                }

                Label {
                    id: word
                    text: `${modelData}`
                    textFormat: Text.RichText
                    font.pixelSize : 15
                }
            }
        }
    }
}
