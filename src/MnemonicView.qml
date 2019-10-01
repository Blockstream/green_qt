import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

GridLayout {
    property alias mnemonic: repeater.model
    flow: GridLayout.LeftToRight
    columns: 6

    Repeater {
        id: repeater

        Item {
            width: 80
            height: 25

            Row {
                spacing: 3

                Label {
                    text: `${index + 1}`
                    textFormat: Text.RichText
                    font.pixelSize : 10
                    color: 'green'
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    text: `${modelData}`
                    textFormat: Text.RichText
                    font.pixelSize : 15
                }
            }
        }
    }
}
