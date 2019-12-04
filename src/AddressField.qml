import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    property alias address: field.text
    property alias label: label.text
    property alias readOnly: field.readOnly

    signal openScanner

    spacing: 5

    Label {
        id: label
        visible: text.length > 0
    }

    RowLayout {
        id: address_row
        spacing: 5

        TextField {
            id: field
            Layout.fillWidth: true
            focus: true
            horizontalAlignment: TextField.AlignHCenter
            placeholderText: 'Insert a bitcoin address'
        }

        Button {
            height: field.height
            width: field.height
            highlighted: false
            flat: true
            icon.source: './assets/svg/qr.svg'
            onClicked: openScanner()
        }
    }
}
