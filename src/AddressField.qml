import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Item {
    property alias address: field.text
    property alias label: label.text
    property alias readOnly: field.readOnly

    clip: true

    height: amount_field.height

    Label {
        id: label
        anchors.left: parent.left
        anchors.baseline: field.baseline
        anchors.margins: 4
        visible: text.length > 0
    }

    TextField {
        id: field
        anchors.left: label.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        focus: true
        horizontalAlignment: TextField.AlignHCenter
        placeholderText: ''
    }
}
