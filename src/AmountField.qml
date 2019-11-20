import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Item {
    property alias amount: amount_field.text
    property alias currency: currency_label.text
    property alias label: label.text
    property alias readOnly: amount_field.readOnly

    clip: true
    height: 70

    Column {
        spacing: 5

        Label {
            id: label
            visible: text.length > 0
        }

        Row {
            spacing: 15
            anchors.left: label.left

            TextField {
                id: amount_field
                width: 250
                focus: true
                horizontalAlignment: TextField.AlignHCenter
                placeholderText: 'Insert amount'
            }

            Label {
                id: currency_label
                visible: currency.length > 0
                anchors.verticalCenter: amount_field.verticalCenter
                anchors.margins: 10

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    color: 'transparent'
                    border.color: 'green'
                    border.width: 1
                }
            }
        }
}
}
