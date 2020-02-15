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

    spacing: 8

    PinField {
        id: field
        focus: true
    }

    GridLayout {
        columns: 3
        columnSpacing: 16
        rowSpacing: 8
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: 9

            Button {
                enabled: !field.valid
                flat: true
                text: modelData + 1
                onClicked: field.addDigit(modelData + 1)
            }
        }

        Button {
            enabled: !field.empty
            flat: true
            icon.source: '../assets/svg/cancel.svg'
            width: 32
            icon.width: 16
            onClicked: field.removeDigit()
        }

        Button {
            enabled: !field.valid
            flat: true
            text: qsTr("0")
            onClicked: field.addDigit(0)
        }

        Button {
            enabled: !field.empty
            flat: true
            icon.source: '../assets/svg/arrow_left.svg'
            icon.height: 24
            onClicked: field.clear()
        }
    }
}
