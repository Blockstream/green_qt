import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

GridLayout {
    property alias mnemonic: repeater.model

    flow: GridLayout.TopToBottom
    rows: 6

    Repeater {
        id: repeater

        Item {
            width: 100
            height: 40

            Label {
                horizontalAlignment: Text.AlignHCenter
                text: `${modelData}<br/>${index + 1}`
                textFormat: Text.RichText
                anchors.centerIn: parent
            }
        }
    }
}
