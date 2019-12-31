import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import '..'

Column {
    property alias pin: field.pin
    property alias valid: field.valid

    function clear() {
        field.clear()
    }

    PinField {
        id: field
        focus: true
    }

    GridLayout {
        columns: 3
        anchors.horizontalCenter: parent.horizontalCenter

        Layout.alignment: Qt.AlignHCenter

        Repeater {
            model: 9

            FlatButton {
                enabled: !field.valid
                text: modelData + 1
                onClicked: field.addDigit(modelData + 1)
            }
        }

        FlatButton {
            enabled: !field.empty
            text: qsTr("id_cancel")
            onClicked: field.removeDigit()
        }

        FlatButton {
            enabled: !field.valid
            text: qsTr("0")
            onClicked: field.addDigit(0)
        }

        FlatButton {
            enabled: !field.empty
            text: qsTr("id_clear")
            onClicked: field.clear()
        }

    }
}
