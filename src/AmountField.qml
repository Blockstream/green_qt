import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Item {
    property alias amount: amount_field.text
    property alias currency: currency_label.text
    property alias label: label.text
    property alias readOnly: amount_field.readOnly

    clip: true

    height: amount_field.height

    Label {
        id: label
        anchors.left: parent.left
        anchors.baseline: amount_field.baseline
        anchors.margins: 4
        visible: text.length > 0
    }

    TextField {
        id: amount_field
        anchors.left: label.right
        anchors.leftMargin: 16
        anchors.right: currency_label.left
        anchors.rightMargin: 16
        focus: true
        horizontalAlignment: TextField.AlignRight
        placeholderText: '0'
    }

    Label {
        id: currency_label
        visible: currency.length > 0
        anchors.right: parent.right
        anchors.baseline: amount_field.baseline
        anchors.margins: 4

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            color: 'transparent'
            border.color: 'white'
            border.width: 1
        }
    }
}
