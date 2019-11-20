import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Item {
    property alias address: field.text
    property alias label: label.text
    property alias readOnly: field.readOnly

    clip: true
    height: 70

    Column {
        spacing: 5

        Label {
            id: label
            visible: text.length > 0
        }

        Row {
            id: address_row
            spacing: 5
            anchors.left: label.left

            TextField {
                id: field
                width: 240
                focus: true
                horizontalAlignment: TextField.AlignHCenter
                placeholderText: 'Insert a bitcoin address'
            }

            Button {
                height: field.height
                width: field.height
                highlighted: false
                flat: true
                icon.source: "./assets/svg/qr.svg"
                onClicked: dialog.open()
            }

        }
    }
}
