import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    property alias amount: amount_field.text
    property string currency
    property alias label: label.text
    property alias readOnly: amount_field.readOnly

    spacing: 5

    Label {
        id: label
        visible: text.length > 0
    }

    RowLayout {
        spacing: 15

        TextField {
            id: amount_field
            width: 250
            focus: true
            horizontalAlignment: TextField.AlignHCenter
            placeholderText: 'Insert amount'
            Layout.fillWidth: true
        }
    }
}
